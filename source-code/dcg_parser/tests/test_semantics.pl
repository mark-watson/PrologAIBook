:- module(test_semantics, []).
:- use_module(library(plunit)).
:- use_module('../prolog/semantics').

:- begin_tests(semantics).

test(every_dog_chases_a_cat, [nondet]) :-
    sentence_logic([every, dog, chases, a, cat], F),
    assertion(F = all(X, imp(dog(X), exists(Y, and(cat(Y), chase(X, Y)))))).

test(proper_noun_sentence, [nondet]) :-
    sentence_logic([john, likes, rex], F),
    assertion(F == like(john, rex)).

test(true_universal) :-
    answer([every, person, likes, a, dog], A),
    assertion(A == yes).

test(false_universal) :-
    answer([every, person, owns, a, dog], A),
    assertion(A == no).

test(existential) :-
    answer([a, cat, sleeps], A),
    assertion(A == yes).

test(ungrammatical, [fail]) :-
    sentence_logic([dog, every, runs], _).

:- end_tests(semantics).
