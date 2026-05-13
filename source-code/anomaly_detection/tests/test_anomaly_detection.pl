:- module(test_anomaly_detection, []).
:- use_module(library(plunit)).
:- use_module('../prolog/anomaly_detection').

:- begin_tests(anomaly_detection).

%% --- Preprocessing ---

test(preprocess_scales_target, [true(Target =:= 0.0)]) :-
    preprocess([[5,1,1,1,2,1,2,1,1,2]], [Row]),
    last(Row, Target).

test(preprocess_scales_target_malignant, [true(Target =:= 1.0)]) :-
    preprocess([[10,10,10,10,10,10,10,10,10,4]], [Row]),
    last(Row, Target).

test(preprocess_features_normalised, [true((Min >= -0.001, Max =< 1.001))]) :-
    preprocess([[5,3,4,1,8,10,4,9,1,4]], [Row]),
    length(Feats, 9),
    append(Feats, [_], Row),
    min_list(Feats, Min),
    max_list(Feats, Max).

%% --- Statistics ---

test(compute_mu_simple, [true(abs(M1 - 2.0) < 0.001)]) :-
    Rows = [[1.0, 10.0], [2.0, 20.0], [3.0, 30.0]],
    compute_mu(Rows, 2, [M1, _M2]).

test(compute_sigma_sq_simple, [true(abs(V - 0.6667) < 0.01)]) :-
    Rows = [[1.0, 10.0], [2.0, 20.0], [3.0, 30.0]],
    compute_mu(Rows, 2, Mu),
    compute_sigma_sq(Rows, 2, Mu, [V|_]).

%% --- Histogram ---

test(histogram_no_crash) :-
    Rows = [[0.1, 0.5], [0.3, 0.7], [0.9, 0.2]],
    print_histogram("Test Feature", Rows, 1, 3).

%% --- Full pipeline ---

test(full_pipeline, [true(nonvar(Model))]) :-
    load_wisconsin_data(Rows),
    train_model(Rows, Model).

:- end_tests(anomaly_detection).
