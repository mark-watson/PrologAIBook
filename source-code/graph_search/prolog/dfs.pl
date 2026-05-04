%% dfs.pl - Depth-First Search with cycle detection
:- module(dfs, [
    dfs/3,
    edge/2
]).

%% Example graph edges
edge(a, b).
edge(a, c).
edge(b, d).
edge(c, d).
edge(d, e).
edge(b, e).

%% dfs(+Start, +Goal, -Path)
dfs(Start, Goal, Path) :-
    dfs(Start, Goal, [Start], Path).

dfs(Goal, Goal, Visited, Path) :-
    reverse(Visited, Path).
dfs(Current, Goal, Visited, Path) :-
    edge(Current, Next),
    \+ member(Next, Visited),
    dfs(Next, Goal, [Next|Visited], Path).
