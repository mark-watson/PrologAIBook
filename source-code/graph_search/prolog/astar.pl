%% astar.pl - A* Heuristic Search
:- module(astar, [
    astar/4
]).

%% astar(+Start, +Goal, +HeuristicPred, -Path)
%% HeuristicPred is a predicate of arity 2: heuristic(Node, Value)
astar(Start, Goal, Heuristic, Path) :-
    call(Heuristic, Start, H),
    astar_loop([node(H, 0, [Start])], Goal, Heuristic, Path).

astar_loop([node(_, _, [Goal|Rest])|_], Goal, _, Path) :-
    reverse([Goal|Rest], Path).
astar_loop([node(_, G, [Current|Rest])|Open], Goal, Heuristic, Path) :-
    findall(
        node(F1, G1, [Next, Current|Rest]),
        (   edge(Current, Next),
            \+ member(Next, [Current|Rest]),
            G1 is G + 1,
            call(Heuristic, Next, H1),
            F1 is G1 + H1
        ),
        Children
    ),
    append(Open, Children, Unsorted),
    sort(1, @=<, Unsorted, Sorted),
    astar_loop(Sorted, Goal, Heuristic, Path).

%% Example graph (reuse from dfs)
:- use_module(dfs, [edge/2]).
