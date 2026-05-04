:- module(test_diagnosis, []).
:- use_module(library(plunit)).
:- use_module('../prolog/diagnosis').

:- begin_tests(diagnosis).

test(diagnose_flu) :-
    diagnose([fever, cough, fatigue, body_aches, headache], diagnosis(flu, _)).

test(diagnose_cold) :-
    diagnose([sneezing, runny_nose, sore_throat], diagnosis(cold, _)).

:- end_tests(diagnosis).
