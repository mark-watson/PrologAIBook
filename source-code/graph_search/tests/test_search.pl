:- module(test_search, []).
:- use_module(library(plunit)).
:- use_module('../prolog/read_graph').
:- use_module('../prolog/dfs').
:- use_module('../prolog/bfs').
:- use_module('../prolog/astar').
:- use_module('../prolog/ids').

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

test(astar_zero_matches_bfs_shortest, [nondet]) :-
    % With a zero heuristic A* is Dijkstra; on the unit-weight
    % sample graph its path length must equal BFS shortest path.
    astar(albany, reno, zero_heuristic, APath),
    bfs(albany, reno, BPath),
    length(APath, AL),
    length(BPath, BL),
    AL =:= BL.

test(astar_optimal_reopened_node) :-
    % Tiny DAG where node b is first reached by the longest path
    % (a->b) but is also reachable via c.  With unit edge weights
    % all shortest paths have length 3; a lazy A* without a
    % best-g closed set could return the longer a->c->b->d.
    % Setup: assert a fresh graph; cleanup: reload sample graph.
    setup_call_cleanup(
        ( clear_graph,
          assertz(read_graph:edge(a, b)),
          assertz(read_graph:edge(b, d)),
          assertz(read_graph:edge(a, c)),
          assertz(read_graph:edge(c, b)),
          assertz(read_graph:edge(c, d)) ),
        ( astar(a, d, zero_heuristic, Path),
          length(Path, Len) ),
        load_graph
    ),
    Len =:= 3.

test(heuristic_is_admissible) :-
    forall(( distance_heuristic(Node, H),
             bfs(Node, reno, P) ),
           ( length(P, Len),
             assertion(H =< Len - 1) )).

test(ids_matches_bfs_length) :-
    ids(albany, reno, IPath),
    once(bfs(albany, reno, BPath)),
    length(IPath, IL),
    length(BPath, BL),
    assertion(IL =:= BL).

test(ids_builtin_finds_path) :-
    ids_builtin(albany, reno, Path),
    Path = [albany|_],
    last(Path, reno).

test(ids_no_path, [fail]) :-
    ids(reno, albany, _).

% h(a) = 3 is the true distance from a, and every other node has
% h = 0, so the heuristic is admissible but not consistent. A* closes
% c through the long path s-p-q-c, then finds the cheaper path s-a-c
% and must re-open c to return the shortest path.
inconsistent_h(a, 3) :- !.
inconsistent_h(_, 0).

test(astar_reopens_closed_node) :-
    setup_call_cleanup(
        ( clear_graph,
          forall(member(F-T, [s-a, a-c, s-p, p-q, q-c, c-m, m-g]),
                 assertz(read_graph:edge(F, T))) ),
        astar(s, g, test_search:inconsistent_h, Path),
        load_graph
    ),
    assertion(Path == [s, a, c, m, g]).

:- end_tests(search).
