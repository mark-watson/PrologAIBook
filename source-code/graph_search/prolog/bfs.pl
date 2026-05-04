%% bfs.pl - Breadth-First Search using a queue
:- module(bfs, [
    bfs/3
]).

:- use_module(dfs, [edge/2]).

%% bfs(+Start, +Goal, -Path)
bfs(Start, Goal, Path) :-
    bfs_queue([[Start]], Goal, Path).

bfs_queue([[Goal|Visited]|_], Goal, Path) :-
    reverse([Goal|Visited], Path).
bfs_queue([[Current|Visited]|Rest], Goal, Path) :-
    findall(
        [Next, Current|Visited],
        (edge(Current, Next), \+ member(Next, [Current|Visited])),
        Children
    ),
    append(Rest, Children, NewQueue),
    bfs_queue(NewQueue, Goal, Path).
