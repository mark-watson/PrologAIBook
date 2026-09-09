:- module(test_janus_ml, []).
% The Makefile runs us from the project root; silence the deprecated
% CWD-relative use_module warning.
:- set_prolog_flag(source_search_working_directory, true).
:- use_module(library(plunit)).

:- dynamic janus_available/0.

:- (   catch(use_module(library(janus)), _, fail),
        current_predicate(janus:py_call/2)
   ->  assertz(janus_available)
   ;   format(user_error,
            "~n[test_janus_ml] Janus unavailable; tests skipped~n", [])
   ).

:- if(janus_available).
:- use_module(prolog/py_sklearn).
:- else.
:- format(user_error,
        "~n[test_janus_ml] NOTE: Janus could not be initialised on this machine~n  (see README Troubleshooting).  Skipping Janus-dependent tests.~n", []).
:- endif.

:- begin_tests(janus_ml).

% Deterministic dataset from README: a 3-row training set whose label
% is the XOR of the two features, and an unlabelled test row [0,0] or
% [1,0] whose expected label under the tiny decision tree is 1/0.

test(py_classify_exact_predictions, [condition(janus_available),
        true(Predictions == [1, 0])]) :-
    py_classify([[1,0,0],[0,1,1],[1,1,0]], [[0,0],[1,0]],
        Predictions).

test(py_classify_accepts_dummy_label_rows, [condition(janus_available),
        true(Predictions == [1])]) :-
    py_classify([[1,0,0],[0,1,1],[1,1,0]], [[0,0,999]],
        Predictions).

test(py_cluster_exact_labels, [condition(janus_available),
        true(Labels == [0, 1, 0, 1])]) :-
    py_cluster([[1,2],[3,4],[1,3],[5,6]], 2, Labels).

test(py_cluster_two_clusters, [condition(janus_available),
        true(Labels == [0, 0, 1, 1])]) :-
    py_cluster([[0.0,0.0],[0.1,0.0],[9.0,9.0],[9.1,9.0]], 2,
        Labels).

% --- Python-side validation ---

test(classify_rejects_empty_train, [condition(janus_available),
        error(janus_error(_, _))]) :-
    py_classify([], [[0,0]], _).

:- end_tests(janus_ml).
