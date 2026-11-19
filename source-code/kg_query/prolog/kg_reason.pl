%% kg_reason.pl - Multi-hop reasoning over knowledge graphs
:- module(kg_reason, [
    entity/2,          % raw facts from sample_data
    relation/3,
    entity_of_type/2,
    relates/3,
    path/3,
    path/4,
    connected/2,
    neighbors/3,
    path_length/3,
    shortest_path/3,
    all_paths/3,
    reachable/2,
    relation_count/2
]).

:- use_module(sample_data).   % static facts: entity/2, relation/3

%% The entity/2 and relation/3 predicates used throughout this module
%% come from sample_data as plain static facts, so no dynamic
%% assertions are needed and re-loading never duplicates data.

%% entity_of_type(?Entity, ?Type) - typed entity accessor
%% (preferred to calling entity/2 directly).
entity_of_type(Entity, Type) :- entity(Entity, Type).

%% relates(?S, ?P, ?O) - relation accessor (preferred to relation/3).
relates(S, P, O) :- relation(S, P, O).

%% path(+Start, +End, -Path) - Find multi-hop path between entities
%% (cycle-free)
path(Start, End, Path) :-
    path(Start, End, [Start], Path).

path(Start, End, Visited, [Start, End]) :-
    relation(Start, _, End),
    \+ member(End, Visited).
path(Start, End, Visited, [Start|Rest]) :-
    relation(Start, _, Mid),
    Mid \= End,
    \+ member(Mid, Visited),
    path(Mid, End, [Mid|Visited], Rest).

%% path(+Start, +End, -Path, +MaxDepth) - depth-limited variant:
%% only paths with at most MaxDepth edges are found.  Always
%% terminates, even for cyclic graphs.
path(Start, End, Path, MaxDepth) :-
    integer(MaxDepth),
    MaxDepth >= 1,
    path_d(Start, End, [Start], Path, MaxDepth).

path_d(Start, End, Visited, [Start, End], MaxDepth) :-
    MaxDepth >= 1,
    relation(Start, _, End),
    \+ member(End, Visited).
path_d(Start, End, Visited, [Start|Rest], MaxDepth) :-
    MaxDepth > 1,
    relation(Start, _, Mid),
    Mid \= End,
    \+ member(Mid, Visited),
    MaxDepth1 is MaxDepth - 1,
    path_d(Mid, End, [Mid|Visited], Rest, MaxDepth1).

%% connected(+A, +B) - Are two entities connected by any path?
connected(A, B) :- path(A, B, _).
connected(A, B) :- path(B, A, _).

%% neighbors(+Entity, -Neighbors, -Predicates) - Find all direct
%% neighbors
neighbors(Entity, Neighbors, Predicates) :-
    findall(Neighbor-Predicate, relation(Entity, Predicate, Neighbor),
        Pairs),
    pairs_keys_values(Pairs, Neighbors, Predicates).

%% shortest_path(+Start, +End, -Path) - A path with the fewest edges,
%% found by breadth-first search. Fails if End cannot be reached.
shortest_path(Start, End, Path) :-
    bfs([[Start]], [Start], End, RevPath),
    reverse(RevPath, Path).

bfs([[End|Rest]|_], _, End, [End|Rest]) :- !.
bfs([[Node|Rest]|Queue], Seen, End, Path) :-
    findall([Next, Node|Rest],
            ( relation(Node, _, Next), \+ memberchk(Next, Seen) ),
            Children0),
    sort(Children0, Children),
    findall(N, member([N|_], Children), NewNodes),
    append(Seen, NewNodes, Seen1),
    append(Queue, Children, Queue1),
    bfs(Queue1, Seen1, End, Path).

%% path_length(+Start, +End, -Length) - Number of edges on a shortest
%% path between two entities.
path_length(Start, End, Length) :-
    shortest_path(Start, End, Path),
    length(Path, N),
    Length is N - 1.

%% all_paths(+Start, +End, -Paths) - Find all cycle-free paths between
%% entities
all_paths(Start, End, Paths) :-
    findall(Path, path(Start, End, Path), Paths).

%% reachable(+Entity, -Reachable) - Entities linked to Entity by a
%% chain of edges: those reachable by following edges forward, plus
%% those that reach Entity. Both searches are breadth-first.
reachable(Entity, Reachable) :-
    reachable_fwd([Entity], [Entity], Fwd),
    reachable_bwd([Entity], [Entity], Bwd),
    append(Fwd, Bwd, All),
    sort(All, Reachable).

reachable_fwd([], _, []).
reachable_fwd([Curr|Queue], Visited, Result) :-
    findall(Next,
        (relation(Curr, _, Next), \+ member(Next, Visited)),
        NewNeighbors),
    append(Queue, NewNeighbors, NewQueue),
    append(Visited, NewNeighbors, NewVisited),
    reachable_fwd(NewQueue, NewVisited, RestResult),
    append(NewNeighbors, RestResult, Result).

reachable_bwd([], _, []).
reachable_bwd([Curr|Queue], Visited, Result) :-
    findall(Prev,
        (relation(Prev, _, Curr), \+ member(Prev, Visited)),
        NewNeighbors),
    append(Queue, NewNeighbors, NewQueue),
    append(Visited, NewNeighbors, NewVisited),
    reachable_bwd(NewQueue, NewVisited, RestResult),
    append(NewNeighbors, RestResult, Result).

%% relation_count(+Predicate, -Count) - Count relations with given
%% predicate
relation_count(Predicate, Count) :-
    findall(_, relation(_, Predicate, _), List),
    length(List, Count).
