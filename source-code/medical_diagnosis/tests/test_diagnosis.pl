:- module(test_diagnosis, []).
:- use_module(library(plunit)).
:- use_module('../prolog/diagnosis').

:- begin_tests(diagnosis).

test(diagnose_flu) :-
    diagnose([fever, cough, fatigue, body_aches, headache],
        diagnosis(flu, _)).

test(diagnose_cold) :-
    diagnose([sneezing, runny_nose, sore_throat], diagnosis(cold, _)).

test(diagnose_pure_repeatable) :-
    findall(D, diagnose(_, diagnosis(D,_)), Ds1),
    findall(D, diagnose(_, diagnosis(D,_)), Ds2),
    Ds1 == Ds2.

test(diagnose_no_matching_disease, [fail]) :-
    diagnose([purple_spots, green_hair, glowing_skin], _).

:- end_tests(diagnosis).
