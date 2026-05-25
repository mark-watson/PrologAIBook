#!/usr/bin/env python3
"""Reformat Prolog source files to fit within 72 columns.

This script handles:
- Comment lines (%, %%, %!, block comments)
- Comment separator lines (===, ---, etc.)
- Multiple facts on one line (stop_word(a). stop_word(b).)
- Long string literals in format/atom_concat calls
- Long clause heads and body goals
- pack.pl title() facts
"""

import re
import sys
import os

MAX_COL = 72


def is_comment_line(line):
    """Check if line is a comment (starts with % after optional whitespace)."""
    stripped = line.lstrip()
    return stripped.startswith('%') or stripped.startswith('/*') or stripped.startswith(' *')


def is_separator_comment(line):
    """Check if line is a separator like %% ====...==== or %% ----...----"""
    stripped = line.rstrip()
    # Match patterns like %% ===...=== or %% ---...---
    return bool(re.match(r'^(\s*%%?\s*)(={4,}|~{4,}|-{4,})\s*$', stripped))


def wrap_comment(line):
    """Wrap a comment line to fit within MAX_COL."""
    stripped = line.rstrip()
    if len(stripped) <= MAX_COL:
        return [stripped]

    # Detect comment prefix
    match = re.match(r'^(\s*)(%%|%!|%|\*)(\s*)', stripped)
    if not match:
        return [stripped]  # Can't parse, leave as-is

    indent = match.group(1)
    marker = match.group(2)
    spacing = match.group(3)

    prefix = indent + marker + spacing
    rest = stripped[len(prefix):]

    # For separator lines, just truncate
    if is_separator_comment(stripped):
        # Find the repeated char
        m = re.match(r'^(\s*%%?\s*)(=+|~+|-+)\s*$', stripped)
        if m:
            pfx = m.group(1)
            char = m.group(2)[0]
            fill_len = MAX_COL - len(pfx)
            return [pfx + char * fill_len]

    if marker.startswith('%'):
        next_marker = '%'
    else:
        next_marker = marker
    next_prefix = indent + next_marker + spacing

    # Word-wrap the comment text
    words = rest.split()
    lines = []
    current = prefix
    current_prefix = prefix
    for word in words:
        test = current + word
        if len(test) > MAX_COL and current.rstrip() != current_prefix.rstrip():
            lines.append(current.rstrip())
            current = next_prefix + word + ' '
            current_prefix = next_prefix
        else:
            current += word + ' '
    if current.rstrip() and current.rstrip() != current_prefix.rstrip():
        lines.append(current.rstrip())
    elif current.strip():
        lines.append(current.rstrip())

    return lines if lines else [stripped]


def has_multiple_facts(line):
    """Check if line has multiple independent facts like stop_word(a). stop_word(b)."""
    stripped = line.strip()
    # Look for pattern: term. term. (multiple periods followed by more terms)
    # Simple heuristic: count "). " patterns
    parts = re.split(r'\)\.\s+', stripped)
    return len(parts) > 1 and not stripped.startswith('%')


def split_multiple_facts(line):
    """Split multiple facts on one line into separate lines."""
    stripped = line.strip()
    indent = line[:len(line) - len(line.lstrip())]

    # Split on "). " but keep the ")."
    # Use regex to find complete facts
    facts = re.findall(r'[^.]+\.', stripped)
    result = []
    for fact in facts:
        fact = fact.strip()
        if fact:
            result.append(indent + fact)
    return result


def is_in_string(line, pos):
    """Check if position pos in line is inside a string literal."""
    in_single = False
    in_double = False
    i = 0
    while i < pos:
        c = line[i]
        if c == "'" and not in_double:
            # Check for escaped quote
            if i + 1 < len(line) and line[i+1] == "'":
                i += 2
                continue
            in_single = not in_single
        elif c == '"' and not in_single:
            if i + 1 < len(line) and line[i+1] == '"':
                i += 2
                continue
            in_double = not in_double
        i += 1
    return in_single or in_double


def find_break_point(line, max_col=MAX_COL):
    """Find a good break point for a Prolog line.

    Tries to break at:
    1. After a comma not inside strings/parens-depth>1
    2. After an operator (:-,  ->, ;)
    3. At a space
    """
    if len(line) <= max_col:
        return -1

    # Track parenthesis/bracket depth and string context
    depth = 0
    in_single = False
    in_double = False
    best_break = -1

    for i, c in enumerate(line):
        if i >= max_col and best_break > 0:
            break

        # Handle string tracking
        if c == "'" and not in_double:
            if i + 1 < len(line) and line[i+1] == "'":
                continue  # escaped
            in_single = not in_single
            continue
        if c == '"' and not in_single:
            if i + 1 < len(line) and line[i+1] == '"':
                continue  # escaped
            in_double = not in_double
            continue

        if in_single or in_double:
            continue

        if c in '([':
            depth += 1
        elif c in ')]':
            depth -= 1
        elif c == ',' and i < max_col:
            best_break = i + 1  # break after comma
        elif c == ' ' and i < max_col:
            # Check if this is after a good operator
            before = line[:i].rstrip()
            if before.endswith('->') or before.endswith(';') or before.endswith(':-'):
                best_break = i + 1
            elif best_break < 0 or (i > best_break and i < max_col):
                best_break = i + 1

    # If no break found within max_col, try to find ANY break point
    if best_break < 0:
        for i, c in enumerate(line):
            if c == ' ' and not is_in_string(line, i):
                best_break = i + 1
                if i >= len(line) // 3:  # prefer breaking after at least 1/3
                    break

    return best_break


def compute_indent(line, break_pos):
    """Compute indentation for continuation line."""
    stripped = line.lstrip()
    base_indent = len(line) - len(stripped)

    # If the line starts with a comment, use comment prefix
    if stripped.startswith('%'):
        return line[:base_indent] + '%    '

    # Look for opening paren/bracket to align to
    depth = 0
    last_open = -1
    in_single = False
    in_double = False

    for i in range(min(break_pos, len(line))):
        c = line[i]
        if c == "'" and not in_double:
            in_single = not in_single
            continue
        if c == '"' and not in_single:
            in_double = not in_double
            continue
        if in_single or in_double:
            continue
        if c in '([':
            depth += 1
            last_open = i
        elif c in ')]':
            depth -= 1

    # Default: indent by 4 from base
    indent = base_indent + 4
    if indent > 20:
        indent = base_indent + 4

    return ' ' * indent


def wrap_prolog_line(line, depth=0):
    """Wrap a single Prolog code line to fit within MAX_COL."""
    if len(line.rstrip()) <= MAX_COL:
        return [line.rstrip()]

    # Prevent infinite recursion
    if depth > 20:
        return [line.rstrip()]

    stripped = line.rstrip()

    # Handle comment lines
    if is_comment_line(stripped):
        return wrap_comment(stripped)

    # Handle multiple facts on one line
    if has_multiple_facts(stripped):
        facts = split_multiple_facts(stripped)
        result = []
        for fact in facts:
            if len(fact) > MAX_COL:
                result.extend(wrap_prolog_line(fact, depth + 1))
            else:
                result.append(fact)
        return result

    # Try to break the line
    break_pos = find_break_point(stripped)
    if break_pos <= 0 or break_pos >= len(stripped):
        return [stripped]  # Can't break, return as-is

    first_part = stripped[:break_pos].rstrip()
    rest = stripped[break_pos:].lstrip()

    if not rest:
        return [first_part]

    indent = compute_indent(stripped, break_pos)
    continuation = indent + rest

    # Only recurse if we made the continuation shorter
    # than the original line
    if len(continuation) > MAX_COL and len(continuation) < len(stripped):
        wrapped_rest = wrap_prolog_line(continuation, depth + 1)
        return [first_part] + wrapped_rest
    elif len(continuation) > MAX_COL:
        # Can't make progress, just return the two parts
        return [first_part, continuation]
    else:
        return [first_part, continuation]


def reformat_file(filepath):
    """Reformat a single Prolog file to fit within MAX_COL columns."""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    changed = False

    for line in lines:
        line_stripped = line.rstrip('\n').rstrip('\r')

        if len(line_stripped) <= MAX_COL:
            new_lines.append(line_stripped)
            continue

        wrapped = wrap_prolog_line(line_stripped)
        if wrapped != [line_stripped]:
            changed = True
        new_lines.extend(wrapped)

    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            for line in new_lines:
                f.write(line + '\n')
        return True
    return False


def check_file(filepath):
    """Check if file has lines exceeding MAX_COL."""
    violations = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f, 1):
            line = line.rstrip('\n').rstrip('\r')
            if len(line) > MAX_COL:
                violations.append((i, len(line), line))
    return violations


def main():
    import glob

    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file_or_directory> [--check]")
        sys.exit(1)

    target = sys.argv[1]
    check_only = '--check' in sys.argv

    if os.path.isfile(target):
        files = [target]
    elif os.path.isdir(target):
        files = sorted(glob.glob(os.path.join(target, '**', '*.pl'), recursive=True))
    else:
        print(f"Error: {target} not found")
        sys.exit(1)

    total_changed = 0
    total_remaining = 0

    for filepath in files:
        if check_only:
            violations = check_file(filepath)
            if violations:
                total_remaining += len(violations)
                print(f"\n{filepath}:")
                for lineno, length, content in violations:
                    print(f"  L{lineno}: [{length}] {content[:80]}...")
        else:
            # Run multiple passes to handle cascading wraps
            for pass_num in range(5):
                changed = reformat_file(filepath)
                if not changed:
                    break

            violations = check_file(filepath)
            if violations:
                total_remaining += len(violations)
                print(f"REMAINING: {filepath} ({len(violations)} lines still > {MAX_COL})")
                for lineno, length, content in violations:
                    print(f"  L{lineno}: [{length}] {content[:80]}...")
            else:
                total_changed += 1

    if check_only:
        print(f"\n{total_remaining} lines exceed {MAX_COL} columns across {len(files)} files")
    else:
        print(f"\n{total_changed} files reformatted, {total_remaining} lines still need attention")


if __name__ == '__main__':
    main()
