%% dfs.pl - Depth-First Search with cycle detection
:- module(dfs, [
    dfs/3
]).

:- use_module(read_graph, [edge/2]).

%% dfs(+Start, +Goal, -Path)
dfs(Start, Goal, Path) :-
    dfs(Start, Goal, [Start], Path).

dfs(Goal, Goal, Visited, Path) :-
    reverse(Visited, Path).
dfs(Current, Goal, Visited, Path) :-
    edge(Current, Next),
    \+ member(Next, Visited),
    dfs(Next, Goal, [Next|Visited], Path).
