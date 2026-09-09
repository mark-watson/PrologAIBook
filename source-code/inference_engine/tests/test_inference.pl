:- module(test_inference, []).
:- use_module(library(plunit)).
:- use_module('../prolog/forward_chain').
:- use_module('../prolog/backward_chain').

:- begin_tests(forward_chain, [setup(reset_kb),
    cleanup(reset_kb)]).

test(derives_new_fact, [nondet]) :-
    add_fact(raining),
    add_rule([raining], wet_ground),
    forward_chain,
    derived_fact(wet_ground).

test(run_leaves_clean_kb_after_reset) :-
    add_fact(raining),
    add_rule([raining], wet_ground),
    forward_chain,
    reset_kb,
    \+ derived_fact(_).

:- end_tests(forward_chain).

:- begin_tests(backward_chain, [setup(reset_bc_kb),
    cleanup(reset_bc_kb)]).

test(facts_only, [nondet]) :-
    assertz(backward_chain:bc_fact(sky_blue)),
    backward_chain:prove(sky_blue, Proof),
    Proof == fact(sky_blue).

test(one_level_rule, [nondet]) :-
    assertz(backward_chain:bc_fact(raining)),
    assertz(backward_chain:bc_rule([raining], wet_ground)),
    backward_chain:prove(wet_ground, Proof),
    Proof == rule(wet_ground, [fact(raining)]).

test(recursive_rule, [nondet]) :-
    assertz(backward_chain:bc_fact(edge(a, b))),
    assertz(backward_chain:bc_fact(edge(b, c))),
    assertz(backward_chain:bc_rule([edge(X, Y)], path(X, Y))),
    assertz(backward_chain:bc_rule([edge(X, Y), path(Y, Z)], path(X, Z))),
    backward_chain:prove(path(a, c), _),
    \+ backward_chain:prove(path(c, a), _).

test(cyclic_rules_fail, [fail]) :-
    assertz(backward_chain:bc_rule([b], a)),
    assertz(backward_chain:bc_rule([a], b)),
    backward_chain:prove(a, _).

:- end_tests(backward_chain).
