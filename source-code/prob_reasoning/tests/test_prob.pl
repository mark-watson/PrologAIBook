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

:- begin_tests(complex_weather).

test(complex_base_low_pressure) :-
    prob_query(low_pressure, P),
    P =:= 0.5.

test(complex_derived_unstable_air) :-
    prob_query(unstable_air, P),
    P =:= 0.4.

test(complex_derived_thick_clouds) :-
    prob_query(thick_clouds, P),
    P =:= 0.1.

test(complex_derived_frontal_zone) :-
    prob_query(frontal_zone, P),
    P =:= 0.15.

test(complex_derived_storm_system) :-
    prob_query(storm_system, P),
    P =:= 0.06.

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

:- end_tests(prob_reasoning).
