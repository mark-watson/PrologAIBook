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

test(rank_partial_match) :-
    rank_diagnoses([sneezing, runny_nose], Ranked),
    Ranked = [match(S1, D1, _, Missing1), match(S2, D2, _, _)|_],
    assertion(S1 =:= 0.67), assertion(S2 =:= 0.67),
    msort([D1, D2], Ds), assertion(Ds == [allergy, cold]),
    assertion(length(Missing1, 1)).

test(rank_full_match_first) :-
    rank_diagnoses([fever, cough, fatigue, body_aches], [First|_]),
    assertion(First = match(1.0, flu, _, [])).

test(rank_no_overlap) :-
    rank_diagnoses([purple_spots], Ranked),
    assertion(Ranked == []).

:- end_tests(diagnosis).
