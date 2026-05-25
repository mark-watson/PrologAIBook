%% kg_reason.pl - Multi-hop reasoning over knowledge graphs
:- module(kg_reason, [
    entity/2,
    relation/3,
    path/3,
    connected/2,
    neighbors/3,
    path_length/3,
    all_paths/3,
    reachable/2,
    relation_count/2
]).

:- dynamic entity/2.      % entity(ID, Type)
:- dynamic relation/3.    % relation(From, Predicate, To)

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

%% connected(+A, +B) - Are two entities connected by any path?
connected(A, B) :- path(A, B, _).
connected(A, B) :- path(B, A, _).

%% neighbors(+Entity, -Neighbors, -Predicates) - Find all direct
%% neighbors
neighbors(Entity, Neighbors, Predicates) :-
    findall(Neighbor-Predicate, relation(Entity, Predicate, Neighbor),
        Pairs),
    pairs_keys_values(Pairs, Neighbors, Predicates).

%% path_length(+Start, +End, -Length) - Find length of a path between
%% entities
path_length(Start, End, Length) :-
    path(Start, End, P),
    !,
    length(P, Length).

%% all_paths(+Start, +End, -Paths) - Find all cycle-free paths between
%% entities
all_paths(Start, End, Paths) :-
    findall(Path, path(Start, End, Path), Paths).

%% reachable(+Entity, -Reachable) - Find all entities reachable from
%% Entity (BFS, bidirectional)
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
