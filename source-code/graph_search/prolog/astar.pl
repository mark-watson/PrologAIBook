%% astar.pl - A* Heuristic Search
:- module(astar, [
    astar/4,
    distance_heuristic/2,
    zero_heuristic/2
]).

:- use_module(dfs, [edge/2]).

%% Safe call: if Heuristic(Node, Value) fails with existence error, return 0.
safe_call(Callable, Node, Value) :-
    catch(call(Callable, Node, Value), _, Value = 0).

%% A* search: accepts both string designators ('h/2') and callable terms (?(-N,-V)).
astar(Start, Goal, Heuristic, Path) :-
    safe_call(Heuristic, Start, H0),
    H is H0 + 0,
    astar_loop([node(H, 0, [Start])], Goal, Heuristic, Path).

astar_loop([node(_, _, [Goal|Rest])|_], Goal, _, Path) :-
    reverse([Goal|Rest], Path).
astar_loop([node(_, G, [Current|Rest])|Open], Goal, Heuristic, Path) :-
    findall(
        node(F1, G1, [Next, Current|Rest]),
            (   edge(Current, Next),
                \+ member(Next, [Current|Rest]),
            G1 is G + 1,
            safe_call(Heuristic, Next, H0),
            H is H0 + 0,
            F1 is G1 + H
            ),
        Children
       ),
    append(Open, Children, Unsorted),
    sort(1, @=<, Unsorted, Sorted),
    astar_loop(Sorted, Goal, Heuristic, Path).

%% Zero heuristic: admissible for uniform-weight graphs (all edge weights = 1).
%% Useful as a baseline for testing A* correctness.
zero_heuristic(_, 0).

%% Example heuristic: estimated remaining distance to goal
%% Admissible (never overestimates) for this uniform-weight graph.
distance_heuristic(e, 0).
distance_heuristic(d, 1).
distance_heuristic(b, 1).
distance_heuristic(c, 2).
distance_heuristic(a, 2).
