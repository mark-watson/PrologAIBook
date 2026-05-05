:- module(test_kg, []).
:- use_module(library(plunit)).
:- use_module('../prolog/kg_builder').

:- begin_tests(kg_builder).

test(add_and_query, [cleanup(retractall(kg_builder:triple(_,_,_)))]) :-
    add_triple(john, works_at, acme),
    query_triples(john, works_at, acme).

test(no_duplicates, [cleanup(retractall(kg_builder:triple(_,_,_)))]) :-
    add_triple(john, works_at, acme),
    add_triple(john, works_at, acme),
    findall(_, query_triples(john, works_at, acme), Results),
    length(Results, 1).

:- end_tests(kg_builder).
