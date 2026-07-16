# Examples Using Scryer Prolog (The Modern Wave)

Scryer Prolog is a modern Prolog implementation written in Rust that aims for strict ISO compliance and efficient memory usage. Its standout feature is an incredibly memory-efficient representation of strings, making Definite Clause Grammars highly practical for processing large volumes of text.

{width: "80%"}
![Architecture diagram for the Scryer DCG example](FIG_scryer_dcg.jpg)

## Why Scryer Prolog?

Scryer Prolog began in 2018 as an effort by Mark Thom to build a Prolog system that takes ISO conformance seriously while leveraging modern systems programming techniques. Written in Rust, it benefits from Rust's memory safety guarantees, fearless concurrency, and zero-cost abstractions. The result is an implementation that is both correct and efficient.

Three design priorities distinguish Scryer from other implementations:

1. **Strict ISO Compliance**: Scryer aims to be the most standards-conformant Prolog available. It faithfully implements the ISO Prolog standard (ISO/IEC 13211-1), including correct handling of the occurs check, arithmetic exceptions, and module semantics. Code written against the ISO specification is more likely to run unmodified on Scryer than on any other system.

2. **Memory-Efficient Strings**: Unlike most Prolog systems that represent strings as linked lists of character codes (consuming 16–24 bytes per character), Scryer uses a compact, packed byte representation internally. This makes string-intensive workloads—especially Definite Clause Grammars applied to large text—dramatically more memory-efficient, often by an order of magnitude.

3. **Rust Foundation**: Scryer's runtime is built on a Warren Abstract Machine (WAM) implemented in Rust. This gives it predictable performance, safe memory management without a garbage collector pause storm, and the ability to integrate with the Rust ecosystem for extensions.

#### When to Choose Scryer over SWI-Prolog

SWI-Prolog remains the best general-purpose choice for most projects: it has the largest library ecosystem, the most mature tooling (graphical debugger, pack manager, web frameworks), and the broadest community support. Choose Scryer when:

- **Text Processing at Scale**: If your application processes large documents, log files, or data streams using DCGs, Scryer's string representation makes workloads feasible that would exhaust memory on other systems.
- **ISO Correctness Matters**: If you are writing portable Prolog code or teaching from the ISO standard, Scryer's strict compliance reduces surprises.
- **Embedding in Rust Applications**: If your host application is written in Rust, Scryer can be embedded as a library crate, avoiding the overhead of inter-process communication.
- **CLP(Z) Over CLP(FD)**: Scryer ships with Markus Triska's `library(clpz)`, the successor to `library(clpfd)`, which offers improved constraint propagation and cleaner semantics.

## Installing Scryer Prolog

Scryer Prolog is distributed as source code and compiled using the Rust toolchain. You will need a working installation of **Rust** (version 1.70 or later) and **Cargo**, Rust's package manager.

#### Installing the Rust Toolchain

If you do not already have Rust installed, the recommended approach is [rustup](https://rustup.rs):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Follow the prompts to install the stable toolchain. After installation, ensure `cargo` is on your PATH by restarting your shell or running `source $HOME/.cargo/env`.

#### Building Scryer Prolog

Clone the repository and build with Cargo:

```bash
git clone https://github.com/mthom/scryer-prolog.git
cd scryer-prolog
cargo build --release
```

The optimized binary will be placed at `target/release/scryer-prolog`. You can copy it to a directory on your PATH:

```bash
cp target/release/scryer-prolog /usr/local/bin/
```

#### Platform-Specific Notes

- **macOS**: Ensure Xcode Command Line Tools are installed (`xcode-select --install`). The build requires a C linker for some native dependencies.
- **Linux**: On Debian/Ubuntu, you may need `build-essential`, `libssl-dev`, and `pkg-config` for a successful build: `sudo apt install build-essential libssl-dev pkg-config`.
- **Windows**: Building on Windows requires the MSVC toolchain. Install Visual Studio Build Tools and select the "C++ build tools" workload. Then build with `cargo build --release` from a Developer Command Prompt.

#### Verifying the Installation

After building, launch the Scryer REPL:

```bash
$ scryer-prolog
?- X is 2 + 3.
   X = 5.
```

Note the different output formatting compared to SWI-Prolog—Scryer indents answers with three spaces and uses a period-terminated style consistent with the ISO standard.

## Differences from SWI-Prolog

Developers moving between SWI-Prolog and Scryer Prolog will encounter several important differences. Understanding these ahead of time prevents frustration.

#### String Handling

This is the most significant difference. In SWI-Prolog, double-quoted strings like `"hello"` are by default treated as string objects (a dedicated type). In Scryer Prolog, double-quoted strings are lists of characters (atoms of length 1), following the ISO standard. This means:

```prolog
%% SWI-Prolog (default flags)
?- X = "hello".
X = "hello".         % A string object

%% Scryer Prolog
?- X = "hello".
   X = "hello".      % A list of chars: [h,e,l,l,o]
```

Scryer's approach is exactly what DCGs expect—a list that can be consumed element by element—which is why DCG-based text processing works so naturally without conversion steps.

#### Constraint Libraries: CLP(Z) vs CLP(FD)

SWI-Prolog provides `library(clpfd)` for finite domain constraint solving. Scryer ships with `library(clpz)`, Markus Triska's successor library. The API is largely compatible—predicates like `ins`, `all_different/1`, `label/1`, and constraint operators (`#=`, `#\=`, `#<`, etc.) work the same way. The key differences are:

- Import `library(clpz)` instead of `library(clpfd)`.
- CLP(Z) operates over arbitrary-precision integers (the "Z" stands for the integers `\mathbb{Z}`$), not just machine-bounded finite domains.
- Some advanced predicates have been renamed or refined for cleaner semantics.

#### Module System

Both systems support ISO-style modules with `:- module(Name, Exports).` declarations. However, SWI-Prolog extends the module system with features like auto-loading, conditional imports, and re-export directives that are not available in Scryer. In practice, simple module declarations are portable between the two systems.

#### Built-in Predicates

SWI-Prolog includes many convenience predicates that are not part of the ISO standard and are therefore absent in Scryer:

| SWI-Prolog Predicate | Scryer Equivalent | Notes |
| :--- | :--- | :--- |
| `format/2` (full) | `format/2` (partial) | Scryer supports core format directives but not all SWI extensions |
| `string_concat/3` | `atom_concat/3` | Scryer uses atoms, not string objects |
| `succ/2` | `X #= Y + 1` | Use CLP(Z) constraints instead |
| `msort/2` | `msort/2` | Available in Scryer's standard library |
| `aggregate_all/3` | `findall/3` + manual | No built-in aggregate library |

#### Library Availability

SWI-Prolog has a vast ecosystem of packs and built-in libraries (HTTP server, JSON parsing, RDF/SPARQL, graphical interfaces). Scryer's library collection is smaller but growing. It includes robust ISO-conformant libraries for lists, DCGs, constraint solving, and format output. For projects requiring web frameworks, database connectors, or foreign language interfaces, SWI-Prolog remains the more practical choice.

#### Interactive REPL Differences

- **Querying**: SWI-Prolog uses `?-` as the prompt. Scryer uses `?-` as well but formats output with indentation.
- **make/0**: SWI-Prolog's `make/0` predicate for hot-reloading modified files is not available in Scryer. You must restart the REPL or reload files manually.
- **Debugging**: SWI-Prolog's `trace/0` and graphical debugger (`gtrace`) have no equivalent in Scryer at the time of writing.

## DCG Processing of Large Text with Scryer

The killer feature of Scryer Prolog for text processing is its memory-efficient string representation. In a traditional Prolog system, the string `"hello world"` stored as a list of character codes occupies roughly 11 cons cells × 16 bytes = 176 bytes of heap memory. Scryer stores the same string in approximately 11 bytes—a 16× improvement. This difference is negligible for small inputs, but becomes decisive when processing megabytes of text.

Consider parsing a 10 MB CSV log file. In SWI-Prolog, loading this file as a character list would consume approximately 160 MB of heap memory just for the string representation, before any parsing data structures are allocated. In Scryer, the same file occupies roughly 10 MB—close to the raw file size. This makes it practical to load entire documents into memory and process them with DCGs in a single pass.

The DCG approach to text processing has several advantages over regex-based alternatives:

1. **Composability**: DCG rules compose naturally. You can build complex parsers from small, testable grammar fragments.
2. **Bidirectionality**: The same grammar can both parse and generate text (though generation is more useful for structured data than natural language).
3. **Integrated Logic**: Semantic actions inside `{ ... }` allow you to validate, transform, and annotate data during the parse without a separate post-processing step.
4. **Backtracking for Ambiguity**: When the input is ambiguous (multiple valid parses), Prolog's backtracking explores all alternatives automatically.

The example below shows how the `text_dcg` module parses CSV lines and key-value pairs. The `parse_csv_line/2` predicate handles both quoted and unquoted fields, and `parse_key_value/2` splits `key=value` strings into structured pairs—tasks that are common in log processing, configuration file parsing, and data ingestion pipelines.

The **scryer_dcg** project demonstrates text processing DCGs designed for Scryer. Here is the file **scryer_dcg/prolog/text_dcg.pl**:

```prolog
:- module(text_dcg, [
    parse_csv_line/2,
    parse_key_value/2,
    extract_emails/2
]).

%% parse_csv_line(+Line, -Fields)
%% Parse a CSV line into a list of fields
parse_csv_line(Line, Fields) :-
    phrase(csv_line(Fields), Line).

csv_line([Field|Fields]) --> csv_field(Field), ",", csv_line(Fields).
csv_line([Field]) --> csv_field(Field).

csv_field(Field) --> "\"", quoted_chars(Chars), "\"",
    { atom_chars(Field, Chars) }.
csv_field(Field) --> unquoted_chars(Chars),
    { atom_chars(Field, Chars) }.

quoted_chars([C|Cs]) --> [C], { C \= ('"') }, quoted_chars(Cs).
quoted_chars([]) --> [].

unquoted_chars([C|Cs]) --> [C], { C \= (','), C \= ('\n') },
    unquoted_chars(Cs).
unquoted_chars([]) --> [].

%% parse_key_value(+String, -Pair)
parse_key_value(String, Key-Value) :-
    phrase(kv_pair(Key, Value), String).

kv_pair(Key, Value) --> word(KeyChars), "=", rest(ValChars),
    { atom_chars(Key, KeyChars), atom_chars(Value, ValChars) }.

word([C|Cs]) --> [C], { C \= ('=') }, word(Cs).
word([]) --> [].

rest([C|Cs]) --> [C], rest(Cs).
rest([]) --> [].
```

## Constraint Logic Programming in Scryer

Scryer Prolog ships with `library(clpz)`, an evolution of the widely-used `library(clpfd)` found in SWI-Prolog. Both libraries were designed by Markus Triska, and CLP(Z) represents his refined vision for constraint programming over integers.

The practical experience of writing CLP code in Scryer is very similar to SWI-Prolog. The core workflow remains the same: declare variables with domains using `ins`, state constraints with relational operators (`#=`, `#\=`, `#<`, `#>`), enforce uniqueness with `all_different/1`, and trigger the search with `label/1`. Code that uses these fundamental predicates will often run on both systems with only the import line changed.

However, CLP(Z) introduces several improvements:

- **Unbounded Integers**: CLP(Z) operates over the full set of mathematical integers, not just a machine-bounded finite domain. This means you can express constraints over arbitrarily large numbers without worrying about overflow.
- **Improved Propagation**: The constraint solver in CLP(Z) uses refined propagation algorithms that can solve some problems with less backtracking than CLP(FD).
- **Cleaner Semantics**: Some predicates have been renamed or redesigned for consistency. For example, `all_different/1` is preferred over `all_distinct/1` (though both are available), and the labeling strategy options have been streamlined.

The two example programs in the **scryer_clp** project demonstrate classic constraint satisfaction problems. The **magic square** solver fills a `3 \times 3`$ grid with digits 1–9 such that every row, column, and diagonal sums to 15. The **SEND + MORE = MONEY** cryptarithmetic puzzle assigns distinct digits to letters so that the arithmetic equation holds. Both are solved purely by declaring constraints and letting the CLP(Z) solver find valid assignments.


{width: "80%"}
![Architecture diagram for the Scryer CLP example](FIG_scryer_clp.jpg)

The **scryer_clp** project contains CLP(Z) examples targeting Scryer Prolog. Here is the file **scryer_clp/prolog/scryer_constraints.pl**:

```prolog
:- module(scryer_constraints, [
    magic_square/1,
    send_more_money/1
]).

:- use_module(library(clpz)).  % Scryer uses clpz, not clpfd

%% magic_square(-Square) - Solve a 3x3 magic square
magic_square(Square) :-
    Square = [A,B,C,D,E,F,G,H,I],
    Square ins 1..9,
    all_different(Square),
    Sum #= 15,
    A + B + C #= Sum,
    D + E + F #= Sum,
    G + H + I #= Sum,
    A + D + G #= Sum,
    B + E + H #= Sum,
    C + F + I #= Sum,
    A + E + I #= Sum,
    C + E + G #= Sum,
    label(Square).

%% send_more_money(-Letters) - Classic cryptarithmetic puzzle
%%   S E N D
%% + M O R E
%% ---------
%% M O N E Y
send_more_money([S,E,N,D,M,O,R,Y]) :-
    Digits = [S,E,N,D,M,O,R,Y],
    Digits ins 0..9,
    all_different(Digits),
```

Note: This module requires Scryer Prolog's `library(clpz)` and will not load under SWI-Prolog. The test suite skips the full CLP tests when running on SWI-Prolog.

## Porting SWI-Prolog Code to Scryer

Porting code between SWI-Prolog and Scryer Prolog is often straightforward for logic-heavy programs, but requires attention to a handful of recurring issues. Here is a practical guide.

#### Step 1: Fix Import Statements

The most mechanical change is updating library imports:

```prolog
%% SWI-Prolog
:- use_module(library(clpfd)).

%% Scryer Prolog
:- use_module(library(clpz)).
```

For standard ISO libraries like `library(lists)` and `library(dcgs)`, both systems generally agree, though the exact set of exported predicates may differ.

#### Step 2: Handle String Representation

If your SWI-Prolog code uses double-quoted strings as string objects (the default), you have two options when porting to Scryer:

- **Preferred**: Rewrite the code to work with character lists, which is what Scryer provides natively. This usually means replacing predicates like `string_concat/3` with `atom_concat/3` or `append/3` on character lists.
- **Minimal Change**: In SWI-Prolog, set the flag `set_prolog_flag(double_quotes, chars).` to match Scryer's behavior. This lets you develop and test on SWI with the same string semantics.

#### Step 3: Replace Non-ISO Built-ins

Search your code for SWI-Prolog-specific predicates and replace them with ISO equivalents or CLP(Z) constraints:

```prolog
%% SWI-Prolog: succ/2
succ(X, Y)       →  Y #= X + 1        %% CLP(Z)

%% SWI-Prolog: plus/3
plus(X, Y, Z)    →  Z #= X + Y        %% CLP(Z)

%% SWI-Prolog: between/3
between(1, 9, X) →  X in 1..9, indomain(X)  %% CLP(Z)
```

#### Step 4: Adapt I/O and Formatting

Scryer supports `format/2` with the core ISO directives (`~w`, `~a`, `~d`, `~n`), but some SWI-Prolog extensions (like `~`-prefixed column alignment and ANSI color codes) are not available. Test all `format/2` calls and simplify any that use extended directives.

#### Step 5: Remove Dynamic Loading Features

SWI-Prolog features like `make/0` (hot reload), `autoload/2`, and conditional compilation with `:- if(current_prolog_flag(...)).` may not be available. Replace them with explicit `:- use_module(...)` directives.

#### Compatibility Checklist

Use this checklist when porting a module:

| Item | Action |
| :--- | :--- |
| `library(clpfd)` imports | Change to `library(clpz)` |
| Double-quoted strings used as objects | Rewrite to use character lists or atoms |
| `succ/2`, `plus/3`, `between/3` | Replace with CLP(Z) constraints |
| `string_concat/3`, `string_lower/2` | Replace with `atom_concat/3`, `downcase_atom/2` |
| `format/2` with extended directives | Simplify to ISO-compatible directives |
| `make/0` or `autoload` | Remove; use explicit imports |
| `assert/retract` on non-dynamic predicates | Add `:- dynamic pred/arity.` declarations |
| `aggregate_all/3` | Rewrite with `findall/3` + manual aggregation |
| SWI-specific packs (e.g., `http`, `semweb`) | No Scryer equivalent; keep on SWI or use FFI |
| `trace/0`, `gtrace` | Not available in Scryer; use `write/1` debugging |

#### Maintaining Dual Compatibility

If you need code to run on both systems, you can use conditional compilation guards in SWI-Prolog:

```prolog
:- if(exists_source(library(clpz))).
:- use_module(library(clpz)).
:- else.
:- use_module(library(clpfd)).
:- endif.
```

This pattern is used in this book's **scryer_clp** project to gracefully skip Scryer-specific modules when running tests under SWI-Prolog.

## Optional Practice Problems

1. **Boolean Constraint Puzzle**: In the `scryer_clp` project, implement a Scryer Prolog script using the `library(clpb)` (Boolean constraints) library to solve a logical puzzle like a truth-teller vs. liar riddle.
2. **Log Parser DCG**: In `scryer_dcg`, write a DCG parser that parses a Scryer-compliant log entry (e.g. `[INFO] 2026-06-23: Message`) and extracts the log level, date, and message.
