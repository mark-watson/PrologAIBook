# Cache Engine

A persistent LLM response cache using SQLite. This is a SWI-Prolog port of the Common Lisp `cache-engine` library.

The cache engine stores text strings in a SQLite database with automatic timestamps, supports keyword-based lookup with AND/OR matching, and provides time-based cleanup to remove stale entries.

## Prerequisites

Install the `prosqlite` SWI-Prolog pack:

```prolog
?- pack_install(prosqlite).
```

## Running Examples

```shell
cd source-code/cache_engine
swipl -s load.pl
```

```prolog
?- cache_open(my_cache, C),
   cache_add(C, 'The quick brown fox jumps over the lazy dog'),
   cache_add(C, 'Common Lisp is powerful'),
   cache_lookup(C, [fox], Results),
   format('Results: ~w~n', [Results]),
   cache_close(C).
Results: [The quick brown fox jumps over the lazy dog]
```

## Running Tests

```shell
swipl -g "['tests/test_cache_engine.pl'], run_tests, halt" -s load.pl
```

## API

### `cache_open(+DbPath, -Connection)`
Opens or creates a SQLite database at DbPath (`.db` extension appended automatically). Returns a Connection handle.

### `cache_add(+Connection, +Text)`
Adds a string to the cache with an automatic timestamp.

### `cache_lookup(+Connection, +SearchTerms, -Results)`
Returns up to 3 matching cached strings. SearchTerms is a list of atoms; all terms must match (AND logic). An empty list returns the most recent entries.

### `cache_lookup(+Connection, +SearchTerms, -Results, +Options)`
Extended lookup with options:
- `limit(N)` — maximum number of results (default 3)
- `match_any(true)` — use OR instead of AND for multiple search terms

### `cache_count(+Connection, -Count)`
Returns the total number of items stored in the cache.

### `cache_clear(+Connection)`
Deletes all items from the cache.

### `cache_clear_older_one_week(+Connection)`
Removes items older than 7 days based on their `created_at` timestamp.

### `cache_close(+Connection)`
Closes the SQLite database connection.

## Architecture

The module wraps the `prosqlite` pack to provide a simple key-value cache API. Each entry is stored with an auto-incrementing ID, the text content, and a `created_at` timestamp. Lookups use SQL `LIKE` clauses for substring matching, connected by AND (default) or OR (`match_any(true)`).

## Book Cover Material, Copyright, and License

This example is released using the Apache 2 license.

Copyright 2022-2026 Mark Watson. All rights reserved.

## This Book is Licensed with Creative Commons Attribution CC BY Version 3
