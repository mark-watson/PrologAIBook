:- module(test_inference, []).
:- use_module(library(plunit)).
:- use_module('../prolog/forward_chain').

:- begin_tests(forward_chain).

test(derives_new_fact, [nondet, setup(reset_facts),
    cleanup(reset_facts)]) :-
    add_fact(raining),
    add_rule([raining], wet_ground),
    forward_chain,
    derived_fact(wet_ground).

reset_facts :-
    retractall(fact(_)),
    retractall(rule(_, _)).

:- end_tests(forward_chain).
