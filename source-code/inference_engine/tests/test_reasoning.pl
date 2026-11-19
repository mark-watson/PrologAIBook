:- module(test_reasoning, []).
:- use_module(library(plunit)).
:- use_module('../prolog/abduction').
:- use_module('../prolog/defaults').

:- begin_tests(abduction).

% Rules in this test module, found because abduce/3 is a
% meta-predicate.
fever :- infection.
fever :- high_temp.


test(two_explanations, all(E == [[rained], [sprinkler_was_on]])) :-
    abduce(abduction:grass_is_wet, [rained, sprinkler_was_on], E).

test(user_module_rules, all(E == [[infection], [high_temp]])) :-
    abduce(fever, [infection, high_temp], E).

test(explain_both_observations) :-
    explanations((abduction:grass_is_wet, abduction:street_is_wet),
                 [rained, sprinkler_was_on, pipe_burst], Sets),
    Sets = [First|_],
    assertion(First == [rained]).

:- end_tests(abduction).

:- begin_tests(defaults, [cleanup(defaults:retractall(penguin(tweety)))]).

test(tweety_flies) :-
    flies(tweety).

test(pingu_does_not_fly, [fail]) :-
    flies(pingu).

test(new_fact_retracts_conclusion, [fail]) :-
    setup_call_cleanup(
        learn(defaults:penguin(tweety)),
        flies(tweety),
        forget(defaults:penguin(tweety))).

:- end_tests(defaults).
