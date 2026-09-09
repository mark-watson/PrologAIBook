%% astar.pl - A* Heuristic Search
:- module(astar, [
    astar/4,
    distance_heuristic/2,
    zero_heuristic/2
]).

:- use_module(read_graph, [edge/2]).

%% A* search with a closed set holding best-known g values.
%% When a popped node's recorded g is worse than the closed g for
%% that node, it is skipped (lazy re-opening); otherwise it is
%% closed and expanded.  Heuristic may be a callable term.
astar(Start, Goal, Heuristic, Path) :-
    safe_call(Heuristic, Start, H0),
    astar_loop([node(H0, 0, [Start])], Goal, Heuristic, [], Path).

astar_loop([node(_, _, [Goal|Rest])|_], Goal, _, _Closed, Path) :-
    !,
    reverse([Goal|Rest], Path).
astar_loop([node(_, G, [Current|_])|Open], Goal, Heuristic, Closed, Path) :-
    best_g(Current, Closed, GBest),
    G >= GBest,
    !,                               % stale entry: skip it
    astar_loop(Open, Goal, Heuristic, Closed, Path).
astar_loop([node(_, G, [Current|Rest])|Open], Goal, Heuristic, Closed, Path) :-
    \+ best_g(Current, Closed, _),
    findall(
        node(F1, G1, [Next, Current|Rest]),
        (   edge(Current, Next),
            \+ member(Next, [Current|Rest]),
            G1 is G + 1,
            safe_call(Heuristic, Next, H),
            F1 is G1 + H
        ),
        Children
    ),
    append(Open, Children, Unsorted),
    sort(1, @=<, Unsorted, Sorted),
    astar_loop(Sorted, Goal, Heuristic, [best_g(Current, G)|Closed], Path).

%% best_g(+Node, +Closed, -G) — G is the best g recorded for Node.
best_g(Node, [best_g(Node, G)|_], G) :- !.
best_g(Node, [_|Closed], G) :- best_g(Node, Closed, G).

%% Safe call: evaluate Heuristic(Node, Value).  Only an undefined
%% heuristic predicate (existence error) falls back to 0; any
%% other exception propagates to the caller.
safe_call(Callable, Node, Value) :-
    catch(call(Callable, Node, Value),
          error(existence_error(_, _), _),
          Value = 0).

%% Zero heuristic: admissible for uniform-weight graphs (all edge
%% weights = 1).
%% Useful as a baseline for testing A* correctness.
zero_heuristic(_, 0).

%% Example heuristic: estimated remaining distance to goal (reno).
%% Rough estimates for the sample_graph cities — admissible for
%% uniform-weight graph.
distance_heuristic(reno,      0).
distance_heuristic(portland,  1).
distance_heuristic(quincy,    1).
distance_heuristic(omaha,     2).
distance_heuristic(naples,    2).
distance_heuristic(memphis,   3).
distance_heuristic(lansing,   3).
distance_heuristic(kent,      3).
distance_heuristic(jackson,   4).
distance_heuristic(irving,    4).
distance_heuristic(houston,   4).
distance_heuristic(gary,      5).
distance_heuristic(fresno,    5).
distance_heuristic(eton,      5).
distance_heuristic(detroit,   5).
distance_heuristic(chicago,   6).
distance_heuristic(boston,     6).
distance_heuristic(albany,    7).
