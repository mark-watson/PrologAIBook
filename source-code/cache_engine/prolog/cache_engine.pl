%% cache_engine.pl - Persistent LLM cache using SQLite
%% A SWI-Prolog port of the Common Lisp cache-engine library.
%%
%% Requires: pack(prosqlite) — install with:
%%   ?- pack_install(prosqlite).
%%
%% Copyright 2022-2026 Mark Watson. All rights reserved.

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
%% Opens (or creates) a SQLite database at DbPath and ensures the
%% cache table exists.  Returns the Connection alias.
%% DbPath should be the base name without extension — prosqlite
%% appends '.db' automatically via the ext(db) option.
cache_open(DbPath, Connection) :-
    gensym(cache_db_, Connection),
    sqlite_connect(DbPath, Connection, [ext(db), exists(false)]),
    ensure_cache_table(Connection).

ensure_cache_table(Conn) :-
    atom_concat(
        'CREATE TABLE IF NOT EXISTS cache ',
        '(id INTEGER PRIMARY KEY, ',
        S1),
    atom_concat(
        S1,
        'content TEXT, ',
        S2),
    atom_concat(
        S2,
        'created_at DATETIME DEFAULT ',
        S3),
    atom_concat(
        S3,
        'CURRENT_TIMESTAMP)',
        SQL),
    ( sqlite_query(Conn, SQL, _Row)
    -> true
    ;  true
    ).

%% cache_close(+Connection)
%% Closes the SQLite database connection.
cache_close(Connection) :-
    sqlite_disconnect(Connection).

%% cache_add(+Connection, +Text)
%% Adds a string to the cache.
cache_add(Connection, Text) :-
    escape_sql(Text, Escaped),
    format(atom(SQL), "INSERT INTO cache (content) VALUES ('~w')",
        [Escaped]),
    ( sqlite_query(Connection, SQL, _Row) -> true ; true ).

%% cache_lookup(+Connection, +SearchTerms, -Results)
%% Returns matching cached strings (default limit 3).
%% SearchTerms is a list of atoms/strings to match against content.
%% When SearchTerms is empty, returns up to 3 most recent entries.
cache_lookup(Connection, SearchTerms, Results) :-
    cache_lookup(Connection, SearchTerms, Results, [limit(3)]).

%% cache_lookup(+Connection, +SearchTerms, -Results, +Options)
%% Options: limit(N), match_any(true/false)
%%   limit(N)         — max number of results (default 3)
%%   match_any(true)  — OR matching (default: AND)
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
    ( sqlite_query(Connection, "DELETE FROM cache", _Row)
    -> true ; true ).

%% cache_clear_older_one_week(+Connection)
%% Removes items older than 7 days from the cache.
cache_clear_older_one_week(Connection) :-
    SQL = "DELETE FROM cache WHERE created_at <= datetime('now', '-7 days')",
    ( sqlite_query(Connection, SQL, _Row)
    -> true
    ;  true
    ).

%% --- Helper predicates ---

option_limit(Options, Limit) :-
    ( member(limit(Limit), Options) -> true ; Limit = 3 ).

option_match_any(Options, MatchAny) :-
    ( member(match_any(MatchAny), Options) -> true ; MatchAny = false ).

%% build_where_clause(+Terms, +MatchAny, -Clause)
%% Builds a SQL WHERE clause from search terms.
build_where_clause([Term], _, Clause) :-
    escape_sql(Term, Escaped),
    format(atom(Clause), "content LIKE '%~w%'", [Escaped]).
build_where_clause([Term|Rest], MatchAny, Clause) :-
    Rest \= [],
    ( MatchAny = true -> Connector = " OR " ; Connector = " AND " ),
    escape_sql(Term, Escaped),
    format(atom(TermClause), "content LIKE '%~w%'", [Escaped]),
    build_where_clause(Rest, MatchAny, RestClause),
    format(atom(Clause), "~w~w~w", [TermClause, Connector, RestClause]).

%% escape_sql(+Input, -Escaped)
%% Doubles single quotes for safe SQL interpolation.
escape_sql(Input, Escaped) :-
    atom_string(Input, Str),
    split_string(Str, "'", "", Parts),
    atomics_to_text(Parts, "''", Escaped).

%% atomics_to_text(+Parts, +Sep, -Text)
%% Joins a list of strings with separator Sep.
atomics_to_text([P], _, P) :- !.
atomics_to_text([P|Ps], Sep, Text) :-
    atomics_to_text(Ps, Sep, Rest),
    atom_concat(P, Sep, Temp),
    atom_concat(Temp, Rest, Text).
