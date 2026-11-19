%% ids.pl - Iterative Deepening Search
:- module(ids, [
    ids/3,
    ids_builtin/3
]).

:- use_module(read_graph, [edge/2]).
:- use_module(dfs, [dfs/3]).

%% ids(+Start, +Goal, -Path)
%% Iterative Deepening Search: raises the depth limit by one on
%% each pass, so the first path found is a shortest one.
ids(Start, Goal, Path) :-
    between(1, 100, DepthLimit),
    depth_limited_dfs(Start, Goal, [Start], DepthLimit, Path),
    !.

%% depth_limited_dfs(+Current, +Goal, +Visited, +Limit, -Path)
depth_limited_dfs(Goal, Goal, Visited, _, Path) :-
    !,
    reverse(Visited, Path).
depth_limited_dfs(Current, Goal, Visited, Limit, Path) :-
    Limit > 0,
    edge(Current, Next),
    \+ member(Next, Visited),
    NextLimit is Limit - 1,
    depth_limited_dfs(Next, Goal, [Next|Visited], NextLimit, Path).

%% ids_builtin(+Start, +Goal, -Path)
%% The same idea using call_with_depth_limit/3 around dfs/3. The
%% limit counts Prolog call depth, not graph edges.
ids_builtin(Start, Goal, Path) :-
    between(1, 100, Limit),
    call_with_depth_limit(dfs(Start, Goal, Path), Limit, Result),
    Result \== depth_limit_exceeded,
    !.
