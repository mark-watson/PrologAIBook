:- module(test_bayes_net, []).
:- use_module(library(plunit)).
:- use_module('../prolog/bayes_net').

:- begin_tests(bayes_net).

close_to(X, Y) :- abs(X - Y) < 0.0005.

test(worlds_sum_to_one) :-
    aggregate_all(sum(P), (world(W), joint(W, P)), Total),
    assertion(close_to(Total, 1.0)).

test(sixteen_worlds) :-
    aggregate_all(count, world(_), N),
    assertion(N == 16).

test(prior_rain) :-
    prob([rain=true], [], P),
    assertion(close_to(P, 0.5)).

test(rain_given_wet_grass) :-
    prob([rain=true], [wet_grass=true], P),
    assertion(close_to(P, 0.7048)).

test(explaining_away) :-
    % Learning that the sprinkler was on makes rain less likely.
    prob([rain=true], [wet_grass=true], P1),
    prob([rain=true], [wet_grass=true, sprinkler=true], P2),
    assertion(P2 < P1).

:- end_tests(bayes_net).
