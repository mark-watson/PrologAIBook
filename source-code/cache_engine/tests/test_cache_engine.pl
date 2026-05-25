:- module(test_cache_engine, []).
:- use_module(library(plunit)).
:- use_module(library(prosqlite)).
:- use_module('../prolog/cache_engine').

:- begin_tests(cache_engine).

%% Helper to create a fresh cache for testing
setup_cache(Conn) :-
    ( exists_file('test_cache.db') -> delete_file('test_cache.db') ;
        true ),
    cache_open(test_cache, Conn).

teardown_cache(Conn) :-
    cache_close(Conn),
    ( exists_file('test_cache.db') -> delete_file('test_cache.db') ;
        true ).

test(add_and_count, [setup(setup_cache(C)),
    cleanup(teardown_cache(C))]) :-
    cache_add(C, 'The quick brown fox jumps over the lazy dog'),
    cache_add(C, 'Hello world'),
    cache_add(C, 'Common Lisp is powerful'),
    cache_add(C, 'SQLite is a great database'),
    cache_add(C, 'Lisp is the best'),
    cache_count(C, Count),
    assertion(Count == 5).

test(lookup_single_term,
     [nondet, setup(setup_cache(C)), cleanup(teardown_cache(C))]) :-
    cache_add(C, 'The quick brown fox jumps over the lazy dog'),
    cache_add(C, 'Hello world'),
    cache_add(C, 'Common Lisp is powerful'),
    cache_lookup(C, [fox], Results),
    assertion(Results ==
        ['The quick brown fox jumps over the lazy dog']).

test(lookup_multiple_terms_and,
     [nondet, setup(setup_cache(C)), cleanup(teardown_cache(C))]) :-
    cache_add(C, 'Common Lisp is powerful'),
    cache_add(C, 'Lisp is the best'),
    cache_add(C, 'Hello world'),
    cache_lookup(C, ['Lisp', powerful], Results),
    assertion(Results == ['Common Lisp is powerful']).

test(lookup_multiple_terms_or,
     [nondet, setup(setup_cache(C)), cleanup(teardown_cache(C))]) :-
    cache_add(C, 'Common Lisp is powerful'),
    cache_add(C, 'Lisp is the best'),
    cache_add(C, 'Hello world'),
    cache_lookup(C, ['Lisp', world], Results, [match_any(true)]),
    length(Results, Len),
    assertion(Len == 3).

test(lookup_empty_terms,
     [nondet, setup(setup_cache(C)), cleanup(teardown_cache(C))]) :-
    cache_add(C, 'First entry'),
    cache_add(C, 'Second entry'),
    cache_lookup(C, [], Results),
    length(Results, Len),
    assertion(Len == 2).

test(lookup_with_limit,
     [nondet, setup(setup_cache(C)), cleanup(teardown_cache(C))]) :-
    cache_add(C, 'Alpha item'),
    cache_add(C, 'Beta item'),
    cache_add(C, 'Gamma item'),
    cache_add(C, 'Delta item'),
    cache_lookup(C, [item], Results, [limit(2)]),
    length(Results, Len),
    assertion(Len == 2).

test(lookup_no_match,
     [nondet, setup(setup_cache(C)), cleanup(teardown_cache(C))]) :-
    cache_add(C, 'Hello world'),
    cache_lookup(C, [nonexistent], Results),
    assertion(Results == []).

test(clear_cache, [setup(setup_cache(C)), cleanup(teardown_cache(C))])
    :-
    cache_add(C, 'First entry'),
    cache_add(C, 'Second entry'),
    cache_count(C, Before),
    assertion(Before == 2),
    cache_clear(C),
    cache_count(C, After),
    assertion(After == 0).

test(clear_older_one_week,
     [nondet, setup(setup_cache(C)), cleanup(teardown_cache(C))]) :-
    cache_add(C, 'Recent item'),
    %% Insert an old record directly via SQL
    ( sqlite_query(C,





                            "INSERT INTO cache (content, created_at) VALUES ('Old item', datetime('now', '-8 days'))",
        _) -> true ; true ),
    cache_count(C, Before),
    assertion(Before == 2),
    cache_clear_older_one_week(C),
    cache_count(C, After),
    assertion(After == 1),
    cache_lookup(C, [], Remaining),
    assertion(Remaining == ['Recent item']).

test(lookup_the,
     [nondet, setup(setup_cache(C)), cleanup(teardown_cache(C))]) :-
    cache_add(C, 'The quick brown fox jumps over the lazy dog'),
    cache_add(C, 'Hello world'),
    cache_add(C, 'Common Lisp is powerful'),
    cache_add(C, 'SQLite is a great database'),
    cache_add(C, 'Lisp is the best'),
    cache_lookup(C, [the], Results, [limit(10)]),
    length(Results, Len),
    assertion(Len == 2).
    %% "The quick brown fox.

:- end_tests(cache_engine).
