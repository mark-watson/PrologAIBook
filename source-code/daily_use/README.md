# Daily Use — Gemini REPL with Search & Cache

An interactive command-line tool built with SWI-Prolog that provides a REPL for querying Google's Gemini API, with Google Search grounding and a persistent SQLite cache for building LLM context.

This is a SWI-Prolog port of the Common Lisp `daily-use` tool.

## Prerequisites

- **SWI-Prolog** (9.x recommended)
- **prosqlite** pack — `?- pack_install(prosqlite).`
- **GOOGLE_API_KEY** environment variable set

## Quick Start

```bash
export GOOGLE_API_KEY=your-key-here
make run
```

Or run directly:

```bash
swipl run.pl
```

## REPL Commands

| Input | Action |
|-------|--------|
| `<text>` | Ask Gemini a question |
| `!<text>` | Ask with Google Search grounding |
| `>` | Add last answer to persistent cache |
| `!` | Clear cache entries older than 1 week |
| `h` / `help` | Show help |
| `q` / `quit` | Exit |
| `Ctrl-D` | Exit |

## How It Works

- **Cache as context**: Cached entries relevant to your current query (matched by bag-of-words keyword overlap) are prepended to each prompt, giving Gemini targeted context from previous conversations.
- **Search grounding**: Prefix a query with `!` to enable Google Search, useful for current events or factual lookups.
- **Keyword extraction**: Stop words and short words are filtered out; remaining terms are used for fuzzy `LIKE` matching against the SQLite cache.

## Dependencies

- [`cache_engine`](../cache_engine/) — SQLite-backed persistent cache (sibling project)
- `prosqlite` — SWI-Prolog SQLite bindings (pack)

## Running Tests

```bash
make test
```

Tests cover the keyword extraction and context-building logic (pure Prolog, no network required).

## Architecture

The daily_use module sits on top of two existing libraries:

```
┌─────────────┐
│  daily_use   │  ← Interactive REPL
│  (this)      │
├──────┬───────┤
│gemini│cache  │  ← Gemini API + SQLite cache
│  API │engine │
└──────┴───────┘
```

## Book Cover Material, Copyright, and License

This example is released using the Apache 2 license.

Copyright 2022-2026 Mark Watson. All rights reserved.

## This Book is Licensed with Creative Commons Attribution CC BY Version 3
