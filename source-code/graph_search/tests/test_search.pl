:- module(test_search, []).
:- use_module(library(plunit)).
:- use_module('../prolog/read_graph').
:- use_module('../prolog/dfs').
:- use_module('../prolog/bfs').
:- use_module('../prolog/astar').

:- load_graph.

:- begin_tests(search).

test(dfs_finds_path, [nondet]) :-
    dfs(albany, reno, Path),
    is_list(Path),
    Path = [albany|_],
    last(Path, reno).

test(bfs_finds_path, [nondet]) :-
    bfs(albany, reno, Path),
    is_list(Path),
    Path = [albany|_],
    last(Path, reno).

test(dfs_no_path, [fail]) :-
    dfs(reno, albany, _).

test(astar_finds_path, [nondet]) :-
    astar(albany, reno, zero_heuristic, Path),
    is_list(Path),
    Path = [albany|_],
    last(Path, reno).

test(astar_with_heuristic, [nondet]) :-
    astar(albany, reno, distance_heuristic, Path),
    is_list(Path),
    Path = [albany|_],
    last(Path, reno).

:- end_tests(search).
