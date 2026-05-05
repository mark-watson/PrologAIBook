:- module(test_search, []).
:- use_module(library(plunit)).
:- use_module('../prolog/dfs').
:- use_module('../prolog/bfs').

:- begin_tests(search).

test(dfs_finds_path, [nondet]) :-
    dfs(a, e, Path),
    is_list(Path),
    Path = [a|_],
    last(Path, e).

test(bfs_finds_path, [nondet]) :-
    bfs(a, e, Path),
    is_list(Path),
    Path = [a|_],
    last(Path, e).

test(dfs_no_path, [fail]) :-
    dfs(e, a, _).

:- end_tests(search).
