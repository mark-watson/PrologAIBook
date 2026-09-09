:- module(test_prob, []).
:- use_module(library(plunit)).
:- use_module('../prolog/prob_facts').

:- begin_tests(prob_reasoning, [setup(load_example_kb),
    cleanup(load_example_kb)]).

test(direct_fact) :-
    prob_query(cloudy, P),
    abs(P - 0.5) < 0.0001.

test(derived_rain) :-
    prob_query(rain, P),
    abs(P - 0.4) < 0.0001.  % 0.5 * 0.8

test(unknown_fact_fails, [fail]) :-
    prob_query(volcanic_eruption, _).

:- begin_tests(complex_weather).

test(complex_base_low_pressure) :-
    prob_query(low_pressure, P),
    abs(P - 0.5) < 0.0001.

test(complex_derived_unstable_air) :-
    prob_query(unstable_air, P),
    abs(P - 0.4) < 0.0001.

test(complex_derived_thick_clouds) :-
    prob_query(thick_clouds, P),
    abs(P - 0.1) < 0.0001.

test(complex_derived_frontal_zone) :-
    prob_query(frontal_zone, P),
    abs(P - 0.15) < 0.0001.

test(complex_derived_storm_system) :-
    prob_query(storm_system, P),
    abs(P - 0.06) < 0.0001.

test(complex_derived_severe_storm) :-
    prob_query(severe_storm, P),
    abs(P - 0.003) < 0.0001.

test(complex_derived_tornado_risk) :-
    prob_query(tornado_risk, P),
    abs(P - 0.0018) < 0.0001.

test(complex_derived_flash_flood_risk) :-
    prob_query(flash_flood_risk, P),
    abs(P - 0.0024) < 0.0001.

:- end_tests(complex_weather).

:- begin_tests(cycle_protection, [
    cleanup(retractall(prob_facts:prob_rule(_, _, _)))]).

test(cyclic_rules_fail, [fail]) :-
    assertz(prob_facts:prob_rule([b], a, 0.5)),
    assertz(prob_facts:prob_rule([a], b, 0.5)),
    prob_query(a, _).

:- end_tests(cycle_protection).

:- begin_tests(example_kb).

test(load_example_kb_idempotent) :-
    load_example_kb,
    findall(G, prob_facts:prob_rule(_, G, _), Gs1),
    load_example_kb,
    findall(G, prob_facts:prob_rule(_, G, _), Gs2),
    length(Gs1, N1),
    length(Gs2, N2),
    N1 =:= N2.

:- end_tests(example_kb).

:- end_tests(prob_reasoning).
