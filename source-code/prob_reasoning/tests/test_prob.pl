:- module(test_prob, []).
:- use_module(library(plunit)).
:- use_module('../prolog/prob_facts').

:- begin_tests(prob_reasoning).

test(direct_fact) :-
    prob_query(cloudy, P),
    P =:= 0.5.

test(derived_rain) :-
    prob_query(rain, P),
    P =:= 0.4.  % 0.5 * 0.8

:- end_tests(prob_reasoning).
