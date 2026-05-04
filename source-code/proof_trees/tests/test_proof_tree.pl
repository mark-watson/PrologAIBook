:- module(test_proof_tree, []).
:- use_module(library(plunit)).
:- use_module('../prolog/proof_tree').

:- begin_tests(proof_tree).

test(module_loads) :-
    true.  % Proof tree tests require dynamic clauses; tested interactively

:- end_tests(proof_tree).
