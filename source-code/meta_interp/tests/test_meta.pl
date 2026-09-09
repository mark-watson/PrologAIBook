:- module(test_meta, []).
:- use_module(library(plunit)).
:- use_module('../prolog/vanilla').
:- use_module('../prolog/bounded').

%% Test knowledge base (non-module for clause/2 access)
:- dynamic parent_test/2, grandparent_test/2.
parent_test(tom, bob).
parent_test(bob, ann).
grandparent_test(X, Z) :- parent_test(X, Y), parent_test(Y, Z).

:- begin_tests(meta_interpreters).

test(vanilla_solve) :-
    mi_solve(test_meta, parent_test(tom, bob)).

test(bounded_solve) :-
    mi_bounded(test_meta, parent_test(tom, bob), 5).

test(bounded_fail_at_zero, [fail]) :-
    mi_bounded(test_meta, parent_test(tom, bob), 0).

test(vanilla_solve_builtin) :-
    mi_solve(X is 2+3),
    X == 5.

test(vanilla_proof_fact) :-
    mi_solve_proof(test_meta, parent_test(tom, bob), Proof),
    Proof == parent_test(tom, bob)-true.

test(vanilla_proof_rule_tree) :-
    mi_solve_proof(test_meta, grandparent_test(tom, ann), Proof),
    Proof =.. [(-), grandparent_test(tom, ann), BodyProof],
    BodyProof == (parent_test(tom, bob)-true,
                  parent_test(bob, ann)-true).

test(vanilla_proof_builtin) :-
    mi_solve_proof(X is 2+3, Proof),
    X == 5,
    Proof == (X is 2+3)-builtin.

:- end_tests(meta_interpreters).
