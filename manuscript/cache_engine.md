# Cache Engine

Caching LLM responses is a practical optimization that reduces API costs, lowers latency for repeated queries, and makes your applications more resilient to network interruptions. The cache engine presented here stores text responses in a local SQLite database, supports keyword-based retrieval, and automatically cleans up stale entries — a pattern directly applicable to any Prolog system that calls external LLM APIs.

This chapter is a SWI-Prolog port of the Common Lisp `cache-engine` library. The Prolog version uses the `prosqlite` pack for native SQLite access and exposes a clean, modular API.

## Design Overview

The cache engine is built around a single SQLite table:

| Column     | Type     | Description                          |
|------------|----------|--------------------------------------|
| id         | INTEGER  | Auto-incrementing primary key        |
| content    | TEXT     | The cached text string               |
| created_at | DATETIME | Automatic timestamp on insertion     |

The API provides six core operations:

- **cache_open/2** — Create or open a SQLite database file
- **cache_add/2** — Insert a text string into the cache
- **cache_lookup/3,4** — Retrieve matching entries by keyword search
- **cache_count/2** — Count total cached items
- **cache_clear/1** — Remove all entries
- **cache_clear_older_one_week/1** — Remove entries older than 7 days

## Implementation

The cache engine module uses `prosqlite` for SQLite access. Install it with:

{linenos=off}
~~~~~~~~
?- pack_install(prosqlite).
~~~~~~~~

Here is the file **cache_engine/prolog/cache_engine.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
%% cache_engine.pl - Persistent LLM cache using SQLite
:- module(cache_engine, [
    cache_open/2,
    cache_close/1,
    cache_add/2,
    cache_lookup/3,
    cache_lookup/4,
    cache_count/2,
    cache_clear/1,
    cache_clear_older_one_week/1
]).

:- use_module(library(prosqlite)).

%% cache_open(+DbPath, -Connection)
cache_open(DbPath, Connection) :-
    gensym(cache_db_, Connection),
    sqlite_connect(DbPath, Connection, [ext(db), exists(false)]),
    ensure_cache_table(Connection).

ensure_cache_table(Conn) :-
    SQL = 'CREATE TABLE IF NOT EXISTS cache (id INTEGER PRIMARY KEY,
           content TEXT,
           created_at DATETIME DEFAULT CURRENT_TIMESTAMP)',
    ( sqlite_query(Conn, SQL, _Row) -> true ; true ).

%% cache_close(+Connection)
cache_close(Connection) :-
    sqlite_disconnect(Connection).

%% cache_add(+Connection, +Text)
cache_add(Connection, Text) :-
    escape_sql(Text, Escaped),
    format(atom(SQL),
           "INSERT INTO cache (content) VALUES ('~w')", [Escaped]),
    ( sqlite_query(Connection, SQL, _Row) -> true ; true ).

%% cache_lookup(+Connection, +SearchTerms, -Results)
cache_lookup(Connection, SearchTerms, Results) :-
    cache_lookup(Connection, SearchTerms, Results, [limit(3)]).

%% cache_lookup(+Connection, +SearchTerms, -Results, +Options)
cache_lookup(Connection, [], Results, Options) :-
    option_limit(Options, Limit),
    format(atom(SQL),
           "SELECT content FROM cache
            ORDER BY created_at DESC LIMIT ~d", [Limit]),
    findall(Content,
            sqlite_query(Connection, SQL, row(Content)),
            Results).

cache_lookup(Connection, SearchTerms, Results, Options) :-
    SearchTerms \= [],
    option_limit(Options, Limit),
    option_match_any(Options, MatchAny),
    build_where_clause(SearchTerms, MatchAny, WhereClause),
    format(atom(SQL),
           "SELECT content FROM cache WHERE ~w
            ORDER BY created_at DESC LIMIT ~d",
           [WhereClause, Limit]),
    findall(Content,
            sqlite_query(Connection, SQL, row(Content)),
            Results).

%% cache_count(+Connection, -Count)
cache_count(Connection, Count) :-
    sqlite_table_count(Connection, cache, Count).

%% cache_clear(+Connection)
cache_clear(Connection) :-
    ( sqlite_query(Connection, "DELETE FROM cache", _Row)
    -> true ; true ).

%% cache_clear_older_one_week(+Connection)
cache_clear_older_one_week(Connection) :-
    ( sqlite_query(Connection,
        "DELETE FROM cache
         WHERE created_at <= datetime('now', '-7 days')",
        _Row)
    -> true ; true ).
~~~~~~~~

The helper predicates handle SQL construction and escaping:

{lang="prolog",linenos=off}
~~~~~~~~
option_limit(Options, Limit) :-
    ( member(limit(Limit), Options) -> true ; Limit = 3 ).

option_match_any(Options, MatchAny) :-
    ( member(match_any(MatchAny), Options) -> true ; MatchAny = false ).

build_where_clause([Term], _, Clause) :-
    escape_sql(Term, Escaped),
    format(atom(Clause), "content LIKE '%~w%'", [Escaped]).
build_where_clause([Term|Rest], MatchAny, Clause) :-
    Rest \= [],
    ( MatchAny = true -> Connector = " OR "
    ; Connector = " AND " ),
    escape_sql(Term, Escaped),
    format(atom(TermClause), "content LIKE '%~w%'", [Escaped]),
    build_where_clause(Rest, MatchAny, RestClause),
    format(atom(Clause), "~w~w~w",
           [TermClause, Connector, RestClause]).

escape_sql(Input, Escaped) :-
    atom_string(Input, Str),
    split_string(Str, "'", "", Parts),
    atomics_to_text(Parts, "''", Escaped).

atomics_to_text([P], _, P) :- !.
atomics_to_text([P|Ps], Sep, Text) :-
    atomics_to_text(Ps, Sep, Rest),
    atom_concat(P, Sep, Temp),
    atom_concat(Temp, Rest, Text).
~~~~~~~~

## Usage Examples

Open a cache, add entries, and look them up:

{lang="prolog",linenos=off}
~~~~~~~~
?- cache_open(my_cache, C),
   cache_add(C, 'The quick brown fox jumps over the lazy dog'),
   cache_add(C, 'Common Lisp is powerful'),
   cache_add(C, 'SQLite is a great database').

?- cache_lookup(C, [fox], Results).
Results = ['The quick brown fox jumps over the lazy dog'].

?- cache_lookup(C, ['Lisp', powerful], R).
R = ['Common Lisp is powerful'].
~~~~~~~~

Use OR matching to broaden the search:

{lang="prolog",linenos=off}
~~~~~~~~
?- cache_lookup(C, [fox, database], R, [match_any(true)]).
R = ['SQLite is a great database',
     'The quick brown fox jumps over the lazy dog'].
~~~~~~~~

Clean up old entries and close:

{lang="prolog",linenos=off}
~~~~~~~~
?- cache_clear_older_one_week(C).
?- cache_close(C).
~~~~~~~~

## Key Design Decisions

**Why prosqlite?** SWI-Prolog does not ship with a built-in SQLite interface, but the `prosqlite` pack provides native C bindings to `libsqlite3`. This gives us proper SQL semantics, ACID transactions, and the full power of SQLite's query language — including `LIKE` for fuzzy matching and `datetime()` functions for timestamp arithmetic.

**SQL construction vs. parameterized queries.** The `prosqlite` pack does not support parameterized queries (prepared statements with `?` placeholders). We construct SQL strings using `format/2` and escape single quotes in user input via the `escape_sql/2` helper. For a cache engine handling LLM responses, this is sufficient and keeps the code straightforward.

**Connection management.** Each call to `cache_open/2` generates a unique connection alias via `gensym/2`. This allows multiple independent caches to be open simultaneously — useful when different subsystems (e.g., an LLM client and a web scraper) maintain separate caches.

## Practical Applications

This cache engine is designed to sit between your Prolog application and an external LLM API. Common use patterns include:

- **Deduplication**: Before calling an expensive LLM API, look up the cache for similar prior responses.
- **Session context**: Accumulate LLM responses during a session and use `cache_lookup/4` with `match_any(true)` to retrieve relevant context for follow-up queries.
- **Cost control**: Cache responses to avoid redundant API calls, especially during development and testing.
- **Stale data management**: Use `cache_clear_older_one_week/1` in a periodic cleanup to prevent unbounded growth.
