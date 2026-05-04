:- module(test_kg_reason, []).
:- use_module(library(plunit)).
:- use_module('../prolog/kg_reason').

:- begin_tests(kg_reason).

test(direct_relation) :-
    relation(mark, uses, prolog).

test(multi_hop_path) :-
    path(mark, swi, Path),
    length(Path, N),
    N >= 2.

test(connected_entities) :-
    connected(mark, swi).

:- end_tests(kg_reason).
