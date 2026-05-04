%% kg_reason.pl - Multi-hop reasoning over knowledge graphs
:- module(kg_reason, [
    entity/2,
    relation/3,
    path/3,
    connected/2
]).

:- dynamic entity/2.      % entity(ID, Type)
:- dynamic relation/3.    % relation(From, Predicate, To)

%% path(+Start, +End, -Path) - Find multi-hop path between entities
path(Start, End, [Start, End]) :-
    relation(Start, _, End).
path(Start, End, [Start|Rest]) :-
    relation(Start, _, Mid),
    Mid \= End,
    path(Mid, End, Rest).

%% connected(+A, +B) - Are two entities connected by any path?
connected(A, B) :- path(A, B, _).
connected(A, B) :- path(B, A, _).

%% Example knowledge graph
:- assert(entity(mark, person)).
:- assert(entity(prolog, language)).
:- assert(entity(ai, field)).
:- assert(entity(swi, implementation)).
:- assert(relation(mark, writes_about, ai)).
:- assert(relation(mark, uses, prolog)).
:- assert(relation(prolog, implemented_by, swi)).
:- assert(relation(ai, uses, prolog)).
