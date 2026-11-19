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

:- use_module('../prolog/bfs').
:- use_module('../prolog/certainty').
:- use_module('../prolog/tracer').
:- use_module('../prolog/sample_kb').

:- begin_tests(more_meta_interpreters).

test(bounded_builtin) :-
    mi_bounded(test_meta, X is 2 + 3, 1),
    assertion(X == 5).

test(bfs_left_recursion_all_answers) :-
    findall(X, mi_bfs(sample_kb, path(a, X), 1000), Xs),
    sort(Xs, S),
    assertion(S == [a, b, c, d]).

test(bfs_shortest_first) :-
    once(mi_bfs(sample_kb, path(a, X), 1000)),
    assertion(X == b).

test(bfs_gives_up, [fail]) :-
    mi_bfs(sample_kb, path(d, a), 200).

test(cf_all_proofs) :-
    findall(C, mi_cf(sample_kb, see_doctor, C), Cs),
    msort(Cs, [Low, High]),
    assertion(abs(Low - 0.27) < 1.0e-9),
    assertion(abs(High - 0.336) < 1.0e-9).

test(cf_best) :-
    best_cf(sample_kb, see_doctor, CF),
    assertion(abs(CF - 0.336) < 1.0e-9).

test(cf_unprovable, [fail]) :-
    best_cf(sample_kb, chickenpox, _).

test(trace_output) :-
    with_output_to(string(S), mi_trace(sample_kb, grandparent(tom, W))),
    assertion(W == ann),
    assertion(sub_string(S, _, _, _, "EXIT grandparent(tom,ann)")),
    !.

test(trace_failure, [fail]) :-
    with_output_to(string(_), mi_trace(sample_kb, older(bob, tom))).

:- end_tests(more_meta_interpreters).
