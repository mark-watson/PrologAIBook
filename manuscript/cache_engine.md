# Cache Engine

Caching LLM responses is a practical optimization that reduces API costs, lowers latency for repeated queries, and makes your applications more resilient to network interruptions. The cache engine presented here stores text responses in a local SQLite database, supports keyword-based retrieval, and automatically cleans up stale entries, a pattern directly applicable to any Prolog system that calls external LLM APIs.

This chapter is a SWI-Prolog port of the Common Lisp `cache-engine` library. The Prolog version uses the `prosqlite` pack for native SQLite access and exposes a clean, modular API.

## Design Overview

The cache engine is built around a single SQLite table:

| Column     | Type     | Description                          |
|------------|----------|--------------------------------------|
| id         | INTEGER  | Auto-incrementing primary key        |
| content    | TEXT     | The cached text string               |
| created_at | DATETIME | Automatic timestamp on insertion     |

The API provides six core operations:

- **cache_open/2**: Create or open a SQLite database file
- **cache_add/2**: Insert a text string into the cache
- **cache_lookup/3,4**: Retrieve matching entries by keyword search
- **cache_count/2**: Count total cached items
- **cache_clear/1**: Remove all entries
- **cache_clear_older_one_week/1**: Remove entries older than 7 days

## Implementation

The cache engine module uses `prosqlite` for SQLite access. Install it with:

{linenos=off}
~~~~~~~~
?- pack_install(prosqlite).
~~~~~~~~

Here is the file **cache_engine/prolog/cache_engine.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
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

%% NOTE on SQL injection safety: this module relies on string-level
%% SQL because parameterized sqlite_query/4 variable binding is not
%% available in the installed prosqlite version.  We therefore escape
%% single quotes, backslashes, NUL characters, and LIKE wildcards
%% (% and _) before interpolation.

:- if(catch(use_module(library(prosqlite)), _, fail)).

cache_open(DbPath, Connection) :-
    gensym(cache_db_, Connection),
    catch(
        sqlite_connect(DbPath, Connection, [ext(db), exists(false)]),
        E,
        (   print_message(error, cache_engine_error(connect(E))),
            fail
        )),
    ensure_cache_table(Connection).

ensure_cache_table(Conn) :-
    format(atom(SQL),
           "CREATE TABLE IF NOT EXISTS cache ~w~w~w~w",
           ['(id INTEGER PRIMARY KEY, ',
            'content TEXT, ',
            'created_at DATETIME DEFAULT ',
            'CURRENT_TIMESTAMP)']),
    (   sqlite_query(Conn, SQL, _Row)
    ->  true
    ;   print_message(error, cache_engine_error(ensure_table)),
        fail
    ).

%% cache_close(+Connection)
%% Closes the SQLite database connection.
cache_close(Connection) :-
    sqlite_disconnect(Connection).

:- else.

cache_open(_, _) :-
    print_message(warning, cache_engine_error(missing_pack)),
    fail.
cache_close(_) :-
    print_message(warning, cache_engine_error(missing_pack)),
    fail.

:- endif.

%% cache_add(+Connection, +Text)
%% Adds a string to the cache.
cache_add(Connection, Text) :-
    escape_sql(Text, Escaped),
    format(atom(SQL), "INSERT INTO cache (content) VALUES ('~w')",
        [Escaped]),
    catch(
        sqlite_query(Connection, SQL, _Row),
        E,
        (   print_message(error, cache_engine_error(add(E))),
            fail
        )).

%% cache_lookup(+Connection, +SearchTerms, -Results)
%% Returns matching cached strings (default limit 3).
%% SearchTerms is a list of atoms/strings to match against content.
%% When SearchTerms is empty, returns up to 3 most recent entries.
cache_lookup(Connection, SearchTerms, Results) :-
    cache_lookup(Connection, SearchTerms, Results, [limit(3)]).

%% cache_lookup(+Connection, +SearchTerms, -Results, +Options)
%% Options: limit(N), match_any(true/false)
%%   limit(N)         max number of results (default 3)
%%   match_any(true)  OR matching (default: AND)
cache_lookup(Connection, [], Results, Options) :-
    option_limit(Options, Limit),
    format(atom(SQL),
        "SELECT content FROM cache ORDER BY created_at DESC LIMIT ~d",
        [Limit]),
    findall(Content,
        sqlite_query(Connection, SQL, row(Content)),
        Results).

cache_lookup(Connection, SearchTerms, Results, Options) :-
    SearchTerms \= [],
    option_limit(Options, Limit),
    option_match_any(Options, MatchAny),
    build_where_clause(SearchTerms, MatchAny, WhereClause),
    format(atom(SQL),
        "SELECT content FROM cache WHERE ~w ORDER BY created_at DESC LIMIT ~d",
        [WhereClause, Limit]),
    findall(Content,
        sqlite_query(Connection, SQL, row(Content)),
        Results).

%% cache_count(+Connection, -Count)
%% Returns the number of items in the cache.
cache_count(Connection, Count) :-
    sqlite_table_count(Connection, cache, Count).

%% cache_clear(+Connection)
%% Removes all items from the cache.
cache_clear(Connection) :-
    catch(
        sqlite_query(Connection, "DELETE FROM cache", _Row),
        E,
        (   print_message(error, cache_engine_error(clear(E))),
            fail
        )).

%% cache_clear_older_one_week(+Connection)
%% Removes items older than 7 days from the cache.
cache_clear_older_one_week(Connection) :-
    format(atom(SQL),
           "DELETE FROM cache WHERE created_at <= datetime('now', '~w')",
           ['-7 days']),
    catch(
        sqlite_query(Connection, SQL, _Row),
        E,
        (   print_message(error, cache_engine_error(clear_old(E))),
            fail
        )).
~~~~~~~~

The helper predicates handle SQL construction and escaping:

{lang="prolog",linenos=off}
~~~~~~~~
option_limit(Options, Limit) :-
    (   member(limit(Limit), Options)
    ->  (   integer(Limit), Limit > 0
        ->  true
        ;   domain_error(positive_integer, Limit)
        )
    ;   Limit = 3
    ).

option_match_any(Options, MatchAny) :-
    ( member(match_any(MatchAny), Options) -> true ; MatchAny = false ).

%% build_where_clause(+Terms, +MatchAny, -Clause)
%% Builds a SQL WHERE clause from search terms.
%% LIKE wildcards % and _ (and the escape char \\) are escaped so
%% user search terms cannot inject wildcard patterns or SQL.
build_where_clause([Term], _, Clause) :-
    escape_sql_like(Term, Escaped),
    format(atom(Clause),
           "content LIKE '%~w%' ESCAPE '\\'", [Escaped]).
build_where_clause([Term|Rest], MatchAny, Clause) :-
    Rest \= [],
    ( MatchAny = true -> Connector = " OR " ; Connector = " AND " ),
    escape_sql_like(Term, Escaped),
    format(atom(TermClause),
           "content LIKE '%~w%' ESCAPE '\\'", [Escaped]),
    build_where_clause(Rest, MatchAny, RestClause),
    format(atom(Clause), "~w~w~w", [TermClause, Connector, RestClause]).

%% escape_sql(+Input, -Escaped)
%% Escapes single quotes, backslashes, and NUL characters for SQL
%% string interpolation.  Used for values NOT inside LIKE patterns.
escape_sql(Input, Escaped) :-
    atom_string(Input, Str),
    string_codes(Str, Codes),
    escape_sql_codes(Codes, EscapedCodes),
    atom_codes(Escaped, EscapedCodes).

escape_sql_codes([], []).
escape_sql_codes([0|Cs], [0'\\, 0'0|Es]) :- !, escape_sql_codes(Cs, Es).
escape_sql_codes([0'\\|Cs], [0'\\, 0'\\|Es]) :- !, escape_sql_codes(Cs, Es).
escape_sql_codes([0'\'|Cs], [0'\', 0'\'|Es]) :- !, escape_sql_codes(Cs, Es).
escape_sql_codes([C|Cs], [C|Es]) :- escape_sql_codes(Cs, Es).

%% escape_sql_like(+Input, -Escaped)
%% As escape_sql/2, but additionally escapes the LIKE wildcard
%% characters % and _ (with \\ as the LIKE escape character).
escape_sql_like(Input, Escaped) :-
    atom_string(Input, Str),
    string_codes(Str, Codes),
    escape_sql_like_codes(Codes, EscapedCodes),
    atom_codes(Escaped, EscapedCodes).

escape_sql_like_codes([], []).
escape_sql_like_codes([0|Cs], [0'\\, 0'0|Es]) :-
    !, escape_sql_like_codes(Cs, Es).
escape_sql_like_codes([C|Cs], [0'\\, C|Es]) :-
    memberchk(C, [0'%, 0'_, 0'\\]),
    !,
    escape_sql_like_codes(Cs, Es).
escape_sql_like_codes([0'\'|Cs], [0'\', 0'\'|Es]) :-
    !, escape_sql_like_codes(Cs, Es).
escape_sql_like_codes([C|Cs], [C|Es]) :- escape_sql_like_codes(Cs, Es).
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

**Why prosqlite?** SWI-Prolog does not ship with a built-in SQLite interface, but the `prosqlite` pack provides native C bindings to `libsqlite3`. This gives us proper SQL semantics, ACID transactions, and the full power of SQLite's query language, including `LIKE` for fuzzy matching and `datetime()` functions for timestamp arithmetic.

**SQL construction vs. parameterized queries.** The `prosqlite` pack does not support parameterized queries (prepared statements with `?` placeholders). We construct SQL strings using `format/2` and protect them with two escapers: `escape_sql/2` escapes single quotes, backslashes, and NUL characters for plain values, and `escape_sql_like/2` additionally escapes the LIKE wildcards `%` and `_` for search terms inside `LIKE` patterns. For a cache engine handling LLM responses, this is sufficient and keeps the code straightforward.

**Connection management.** Each call to `cache_open/2` generates a unique connection alias via `gensym/2`. This allows multiple independent caches to be open simultaneously, useful when different subsystems (e.g., an LLM client and a web scraper) maintain separate caches.

## Practical Applications

This cache engine is designed to sit between your Prolog application and an external LLM API. Common use patterns include:

- **Deduplication**: Before calling an expensive LLM API, look up the cache for similar prior responses.
- **Session context**: Accumulate LLM responses during a session and use `cache_lookup/4` with `match_any(true)` to retrieve relevant context for follow-up queries.
- **Cost control**: Cache responses to avoid redundant API calls, especially during development and testing.
- **Stale data management**: Use `cache_clear_older_one_week/1` in a periodic cleanup to prevent unbounded growth.

## Optional Practice Problems

1. **Time-To-Live Cache**: In the `cache_engine` project, modify the caching rules to store a timestamp with each cached query, and invalidate any cache entries that are older than a user-specified Time-To-Live (TTL) duration.
2. **Selective Invalidation**: Implement a predicate `invalidate_cache_pattern/1` that accepts a pattern (e.g. `weather(city, _)`), matching and retracting all cached entries corresponding to that pattern.
