# Cache Engine

Caching LLM responses cuts API costs, makes repeated queries faster, and keeps an application working through network outages. The cache engine in this chapter stores text in a local SQLite database, finds entries by keyword, and deletes old entries. Any Prolog program that calls an LLM API can use it; the next chapter does.

This is a SWI-Prolog port of my Common Lisp `cache-engine` library. It uses the `prosqlite` pack for SQLite access.

## Design Overview

The cache engine is built around a single SQLite table:

| Column     | Type     | Description                          |
|------------|----------|--------------------------------------|
| id         | INTEGER  | Auto-incrementing primary key        |
| content    | TEXT     | The cached text string               |
| created_at | DATETIME | Automatic timestamp on insertion     |

The API provides six core operations:

- **cache_open/2**: Create or open a SQLite database file
- **cache_add/2**: Insert a text string into the cache, unless it is already there
- **cache_lookup/3,4**: Retrieve matching entries by keyword search, newest first
- **cache_count/2**: Count total cached items
- **cache_clear/1**: Remove all entries
- **cache_clear_older_one_week/1**: Remove entries older than 7 days

## Implementation

Install `prosqlite` once with the command below. It compiles a small C library, so you need a C compiler and the SQLite headers (on macOS, the Xcode Command Line Tools provide both). The Makefile checks for the pack and prints this command if it is missing.

{linenos=off}
~~~~~~~~
?- pack_install(prosqlite).
~~~~~~~~

Here is the file **cache_engine/prolog/cache_engine.pl**:

```prolog
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

%% NOTE on SQL injection safety: prosqlite has no parameter binding,
%% so we build SQL text and escape values ourselves. In an SQLite
%% string literal the only special character is the single quote,
%% which is written twice. Backslash has no special meaning there. In
%% LIKE patterns we also escape % and _ (and the escape character \
%% itself), using ESCAPE '\'.

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
%% Adds a string to the cache unless the same text is already there.
cache_add(Connection, Text) :-
    escape_sql(Text, Escaped),
    format(atom(SQL),
           "INSERT INTO cache (content) SELECT '~w' WHERE NOT EXISTS (SELECT 1 FROM cache WHERE content = '~w')",
           [Escaped, Escaped]),
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
%% Results are newest first.
cache_lookup(Connection, [], Results, Options) :-
    option_limit(Options, Limit),
    format(atom(SQL),
        "SELECT content FROM cache ORDER BY created_at DESC, id DESC LIMIT ~d",
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
        "SELECT content FROM cache WHERE ~w ORDER BY created_at DESC, id DESC LIMIT ~d",
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
```

`cache_add/2` uses `INSERT ... SELECT ... WHERE NOT EXISTS` to skip text that is already cached. Lookups sort by `created_at` and then by `id`, since entries added in the same second share a timestamp.

The helper predicates build the SQL and escape values:

```prolog
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
%% Make Input safe inside an SQLite string literal by doubling single
%% quotes. A NUL character cannot appear in an SQL literal, so it
%% raises a domain error. Used for values NOT inside LIKE patterns.
escape_sql(Input, Escaped) :-
    atom_string(Input, Str),
    string_codes(Str, Codes),
    (   memberchk(0, Codes)
    ->  domain_error(text_without_nul, Input)
    ;   true
    ),
    escape_sql_codes(Codes, EscapedCodes),
    atom_codes(Escaped, EscapedCodes).

escape_sql_codes([], []).
escape_sql_codes([0'\'|Cs], [0'\', 0'\'|Es]) :- !, escape_sql_codes(Cs, Es).
escape_sql_codes([C|Cs], [C|Es]) :- escape_sql_codes(Cs, Es).

%% escape_sql_like(+Input, -Escaped)
%% As escape_sql/2, but also escapes the LIKE wildcards % and _ and
%% the LIKE escape character \\ itself, each with a \\ in front.
escape_sql_like(Input, Escaped) :-
    atom_string(Input, Str),
    string_codes(Str, Codes),
    (   memberchk(0, Codes)
    ->  domain_error(text_without_nul, Input)
    ;   true
    ),
    escape_sql_like_codes(Codes, EscapedCodes),
    atom_codes(Escaped, EscapedCodes).

escape_sql_like_codes([], []).
escape_sql_like_codes([C|Cs], [0'\\, C|Es]) :-
    memberchk(C, [0'%, 0'_, 0'\\]),
    !,
    escape_sql_like_codes(Cs, Es).
escape_sql_like_codes([0'\'|Cs], [0'\', 0'\'|Es]) :-
    !, escape_sql_like_codes(Cs, Es).
escape_sql_like_codes([C|Cs], [C|Es]) :- escape_sql_like_codes(Cs, Es).
```

## Usage Examples

Open a cache, add entries, and look them up. `cache_open/2` adds the `.db` extension, so this creates **my_cache.db**. A connection is a Prolog atom, so we do everything in one query, between `cache_open/2` and `cache_close/1`:

```prolog
?- cache_open(my_cache, C),
   cache_add(C, 'The quick brown fox jumps over the lazy dog'),
   cache_add(C, 'Common Lisp is powerful'),
   cache_add(C, 'SQLite is a great database'),
   cache_lookup(C, [fox], R1),
   cache_lookup(C, ['Lisp', powerful], R2),
   cache_lookup(C, [fox, database], R3, [match_any(true)]),
   cache_close(C).
C = cache_db_1,
R1 = ['The quick brown fox jumps over the lazy dog'],
R2 = ['Common Lisp is powerful'],
R3 = ['SQLite is a great database',
      'The quick brown fox jumps over the lazy dog'].
```

Several terms must all match by default (`R2`). With `match_any(true)`, any one term is enough (`R3`), and the newest entry comes first. To delete entries more than a week old, call `cache_clear_older_one_week(C)` before closing.

## Key Design Decisions

**Why prosqlite?** SWI-Prolog does not ship with an SQLite interface, but the `prosqlite` pack binds to `libsqlite3` in C. That gives us transactions and SQLite's query language, including `LIKE` for substring search and `datetime()` for date arithmetic.

**Building SQL by hand.** `prosqlite` has no parameterized queries (prepared statements with `?` placeholders), so we build SQL text with `format/2` and escape every value. Escaping must follow SQLite's rules exactly. In an SQLite string literal, the only special character is the single quote, written twice: `'it''s'`. A backslash is an ordinary character, so `escape_sql/2` must *not* double it, or `C:\temp` would be stored as `C:\\temp` and later lookups would miss it. (Other databases, such as MySQL, do treat backslash as an escape, which is how such bugs creep in.) Inside a `LIKE` pattern, `%` and `_` are wildcards. `escape_sql_like/2` puts a backslash before each of them and before backslash itself, and the query declares `ESCAPE '\'`. A NUL character cannot appear in an SQL literal at all, so both escapers reject it. The tests in **tests/test_cache_engine.pl** store and find text with quotes, backslashes, and `%`.

**Connections.** Each call to `cache_open/2` makes a unique connection alias with `gensym/2`, so several caches can be open at once, for example one for an LLM client and one for a web scraper.

## Practical Applications

The cache sits between your Prolog program and an LLM API:

- **Avoiding repeat calls**: Before calling an LLM, look in the cache for a stored answer to a similar request.
- **Session context**: Store LLM replies during a session and use `cache_lookup/4` with `match_any(true)` to pull related context into follow-up prompts. The Daily Use REPL chapter does this.
- **Cost control**: Cached replies save API calls, especially while you develop and test.
- **Cleanup**: Call `cache_clear_older_one_week/1` from time to time so the database does not grow without limit.

## Optional Practice Problems

1. **Time to Live**: Write `cache_clear_older_than(+Connection, +Days)`, which generalizes `cache_clear_older_one_week/1`. Check that `Days` is a positive integer before it goes into the SQL.
2. **Prompt and Response Pairs**: Add a `prompt` column, and write `cache_answer(+Connection, +Prompt, -Response)`, which returns a cached response for an identical prompt or calls `gemini_generate/2` and stores the result.
3. **Selective Delete**: Write `cache_delete_matching(+Connection, +Terms)`, which deletes the entries that `cache_lookup/3` would find for `Terms`. Reuse `build_where_clause/3`.
