:- module(test_meta, []).
:- use_module(library(plunit)).
:- use_module('../prolog/vanilla').
:- use_module('../prolog/bounded').

%% Test knowledge base (non-module for clause/2 access)
:- dynamic grandparent_test/2, parent_test/2.
parent_test(tom, bob).
parent_test(bob, ann).
grandparent_test(X, Z) :- parent_test(X, Y), parent_test(Y, Z).

:- begin_tests(meta_interpreters).

test(vanilla_solve) :-
    mi_solve(parent_test(tom, bob)).

test(bounded_solve) :-
    mi_bounded(parent_test(tom, bob), 5).

test(bounded_fail_at_zero, [fail]) :-
    mi_bounded(parent_test(tom, bob), 0).

:- end_tests(meta_interpreters).
