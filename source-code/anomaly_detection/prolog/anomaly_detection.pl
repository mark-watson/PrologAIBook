%% anomaly_detection.pl — Gaussian anomaly detection
%%
%% Ports the Java AnomalyDetection class to SWI-Prolog.
%% Uses per-feature Gaussian PDF with mean/variance statistics
%% and an epsilon threshold optimised via cross-validation.
%%
%% Copyright 2022-2026 Mark Watson. All rights reserved.
%% Apache 2 license.

:- module(anomaly_detection, [
    load_wisconsin_data/1,      % -Rows
    preprocess/2,               % +RawRows, -Processed
    split_data/4,               % +Rows, -Train, -CV, -Test
    compute_mu/3,               % +Train, +NF, -Mu
    compute_sigma_sq/4,         % +Train, +NF, +Mu, -SigmaSq
    train_model/2,              % +Rows, -Model
    is_anomaly/2,               % +Model, +Row
    evaluate_model/2,           % +Model, +TestRows
    print_histogram/4,          % +Title, +Rows, +Index, +NumBins
    subsample_rows/3            % +Rows, +MaxN, -Sampled
]).

:- use_module(library(csv)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(random)).

%% ---------- Constants ----------

sqrt_2_pi(2.50662827463).

%% The number of features (9 input features + 1 target = 10 columns).
num_columns(10).
num_input_features(9).

%% ---------- Data Loading ----------

%% load_wisconsin_data(-Rows) is det.
%  Load the Wisconsin cancer CSV.  Each row is a list of 10 floats.
%  Subsampled to ~200 rows for Prolog performance.
load_wisconsin_data(Rows) :-
    once(source_file(anomaly_detection:_, ThisFile)),
    file_directory_name(ThisFile, Dir),
    atomic_list_concat([Dir, '/../data/cleaned_wisconsin_cancer_data.csv'], Path),
    csv_read_file(Path, CsvRows,
                  [separator(0',), convert(true), arity(10)]),
    maplist(row_to_list, CsvRows, AllRows),
    once(subsample_rows(AllRows, 200, Rows)).

%% subsample_rows(+Rows, +MaxN, -Sampled) is det.
%  Randomly sample at most MaxN rows, preserving class balance.
subsample_rows(Rows, MaxN, Sampled) :-
    length(Rows, Len),
    (   Len =< MaxN
    ->  Sampled = Rows
    ;   Frac is MaxN / Len,
        include(keep_row(Frac), Rows, Sampled)
    ).

keep_row(Frac, _) :- random(P), P < Frac.

row_to_list(Row, List) :-
    Row =.. [_|List].

%% ---------- Preprocessing ----------

%% preprocess(+RawRows, -Processed) is det.
%  Matches the Java preprocessing:
%    1. Scale features 0-8 by 0.1
%    2. Log-transform:  x_i := log(x_i + 1.2)
%    3. Min-max normalise features 0-8 within each row
%    4. Remap target (column 9): (x - 2) * 0.5  →  {0, 1}
preprocess(Raw, Processed) :-
    maplist(preprocess_row, Raw, Processed).

preprocess_row(Row, Out) :-
    length(Features, 9),
    append(Features, [Target], Row),
    maplist(scale01, Features, Scaled),
    maplist(log_transform, Scaled, Logged),
    min_list(Logged, Min), max_list(Logged, Max),
    Span is Max - Min,
    (   Span =:= 0
    ->  maplist(=( 0.0), Normed)
    ;   maplist(normalise(Min, Span), Logged, Normed)
    ),
    TargetOut is (Target - 2) * 0.5,
    append(Normed, [TargetOut], Out).

scale01(X, Y) :- Y is X * 0.1.
log_transform(X, Y) :- Y is log(X + 1.2).
normalise(Min, Span, X, Y) :- Y is (X - Min) / Span.

%% ---------- Data Splitting ----------

%% split_data(+Rows, -Train, -CV, -Test) is det.
%  Mimics the Java split: 60% training (mostly normal, ~10% anomalies leak),
%  ~28% cross-validation, ~12% test.
%  Fully deterministic — no choicepoints.
split_data(Rows, Train, CV, Test) :-
    maplist(assign_row, Rows, Tagged),
    include(is_train, Tagged, TrainTagged),
    include(is_cv, Tagged, CVTagged),
    include(is_test, Tagged, TestTagged),
    maplist(untag, TrainTagged, Train),
    maplist(untag, CVTagged, CV),
    maplist(untag, TestTagged, Test).

assign_row(Row, Tag-Row) :-
    random(P1),
    last(Row, Target),
    (   P1 < 0.6
    ->  (   Target < 0.5
        ->  Tag = train
        ;   random(P2),
            (   P2 < 0.1
            ->  Tag = train   % leak ~10% anomalies into training
            ;   Tag = skip    % discard anomaly from training
            )
        )
    ;   random(P3),
        (   P3 < 0.7
        ->  Tag = cv
        ;   Tag = test
        )
    ).

is_train(train-_).
is_cv(cv-_).
is_test(test-_).
untag(_-Row, Row).

%% ---------- Statistics ----------

%% compute_mu(+Rows, +NumFeatures, -Mu) is det.
%  Mu is a list of NumFeatures mean values.
compute_mu(Rows, NF, Mu) :-
    length(Rows, N),
    (   N =:= 0
    ->  length(Mu, NF), maplist(=(0.0), Mu)
    ;   numlist(1, NF, Indices),
        maplist(feature_mean(Rows, N), Indices, Mu)
    ).

feature_mean(Rows, N, FIdx, Mean) :-
    maplist(nth1(FIdx), Rows, Vals),
    sumlist(Vals, Sum),
    Mean is Sum / N.

%% compute_sigma_sq(+Rows, +NumFeatures, +Mu, -SigmaSq) is det.
%  Variance for each feature.
compute_sigma_sq(Rows, NF, Mu, SigmaSq) :-
    length(Rows, N),
    (   N =:= 0
    ->  length(SigmaSq, NF), maplist(=(1.0), SigmaSq)
    ;   numlist(1, NF, Indices),
        maplist(feature_var(Rows, N, Mu), Indices, SigmaSq)
    ).

feature_var(Rows, N, Mu, FIdx, Var) :-
    nth1(FIdx, Mu, M),
    maplist(sq_diff(FIdx, M), Rows, Diffs),
    sumlist(Diffs, SumSq),
    Var is SumSq / N.

sq_diff(FIdx, M, Row, D) :-
    nth1(FIdx, Row, X),
    D is (X - M) * (X - M).

%% ---------- Gaussian PDF ----------

%% gaussian_prob(+Row, +Mu, +SigmaSq, +NF, -P) is det.
%  Average per-feature Gaussian PDF value (matches Java p() method).
%  Walks three lists in parallel to avoid nth1 lookups.
gaussian_prob(Row, Mu, SigmaSq, _NF, P) :-
    sqrt_2_pi(S2P),
    num_columns(NC),
    gaussian_sum(Row, Mu, SigmaSq, S2P, 0, 0.0, Sum),
    P is Sum / NC.

%% gaussian_sum(+Row, +Mu, +SigmaSq, +S2P, +Idx, +Acc, -Sum)
%  Walk the first 9 elements (skip target at position 10).
gaussian_sum(_, _, _, _, 9, Acc, Acc) :- !.
gaussian_sum([X|Xs], [M|Ms], [S2|Ss], S2P, I, Acc, Sum) :-
    (   S2 =:= 0
    ->  PDF = 0.0
    ;   Sigma is sqrt(S2),
        Exp is -((X - M) * (X - M)) / (2.0 * S2),
        PDF is (1.0 / (S2P * Sigma)) * exp(Exp)
    ),
    Acc1 is Acc + PDF,
    I1 is I + 1,
    gaussian_sum(Xs, Ms, Ss, S2P, I1, Acc1, Sum).

%% ---------- Training ----------

%% Precompute Gaussian probabilities for a set of rows so the epsilon
%% sweep just iterates over numbers, not full PDF calculations.

%% precompute_probs(+Rows, +Mu, +SigmaSq, +NF, -ProbTargetPairs) is det.
%  Returns a list of prob-target pairs.
precompute_probs([], _, _, _, []).
precompute_probs([Row|Rows], Mu, SigmaSq, NF, [P-T|Rest]) :-
    gaussian_prob(Row, Mu, SigmaSq, NF, P),
    last(Row, T),
    precompute_probs(Rows, Mu, SigmaSq, NF, Rest).

%% count_errors(+ProbTargetPairs, +Epsilon, -Errors) is det.
count_errors([], _, 0).
count_errors([P-T|Rest], Eps, Errors) :-
    count_errors(Rest, Eps, E0),
    (   T > 0.5
    ->  (P > Eps -> Errors is E0 + 1 ; Errors = E0)
    ;   (P < Eps -> Errors is E0 + 1 ; Errors = E0)
    ).

%% search_epsilon(+ProbTargetPairs, -BestEps) is det.
%  Grid search over 20 epsilon values (coarse but fast).
search_epsilon(PTPs, BestEps) :-
    numlist(0, 19, Steps),
    maplist(step_to_epsilon, Steps, Epsilons),
    maplist(count_errors(PTPs), Epsilons, ErrorCounts),
    min_list(ErrorCounts, MinErr),
    nth0(BestIdx, ErrorCounts, MinErr), !,
    nth0(BestIdx, Epsilons, BestEps).

step_to_epsilon(Step, Eps) :-
    Eps is 0.001 + 0.05 * Step.

%% ---------- Model ----------

%% A model is a term:  model(Mu, SigmaSq, NF, Epsilon)

%% train_model(+Rows, -Model) is det.
%  Preprocess, split, compute statistics, search epsilon, evaluate.
train_model(Rows, Model) :-
    preprocess(Rows, Processed),
    once(split_data(Processed, Train, CV, Test)),
    length(Train, NTrain), length(CV, NCV), length(Test, NTest),
    format('Split: ~w train, ~w cv, ~w test~n', [NTrain, NCV, NTest]),
    num_input_features(NF),
    compute_mu(Train, NF, Mu),
    compute_sigma_sq(Train, NF, Mu, SigmaSq),
    precompute_probs(CV, Mu, SigmaSq, NF, CVProbs),
    once(search_epsilon(CVProbs, BestEps)),
    format('~n**** Best epsilon value = ~6f~n', [BestEps]),
    Model = model(Mu, SigmaSq, NF, BestEps),
    evaluate_model(Model, Test), !.

%% is_anomaly(+Model, +Row) is semidet.
%  Succeeds if Row is classified as an anomaly.
is_anomaly(model(Mu, SigmaSq, NF, Eps), Row) :-
    gaussian_prob(Row, Mu, SigmaSq, NF, P),
    P < Eps.

%% ---------- Evaluation ----------

%% evaluate_model(+Model, +TestRows) is det.
%  Compute and print precision, recall, F1 on test data.
evaluate_model(Model, TestRows) :-
    foldl(classify_row(Model), TestRows,
          counts(0,0,0,0), counts(TP,FP,FN,TN)),
    length(TestRows, NTest),
    (   TP + FP =:= 0 -> Precision = 0.0
    ;   Precision is TP / (TP + FP)
    ),
    (   TP + FN =:= 0 -> Recall = 0.0
    ;   Recall is TP / (TP + FN)
    ),
    (   Precision + Recall =:= 0 -> F1 = 0.0
    ;   F1 is 2 * Precision * Recall / (Precision + Recall)
    ),
    format('~n -- number of test examples = ~w~n', [NTest]),
    format(' -- true positives  = ~w~n', [TP]),
    format(' -- false positives = ~w~n', [FP]),
    format(' -- false negatives = ~w~n', [FN]),
    format(' -- true negatives  = ~w~n', [TN]),
    format(' -- precision = ~6f~n', [Precision]),
    format(' -- recall    = ~6f~n', [Recall]),
    format(' -- F1        = ~6f~n', [F1]).

classify_row(Model, Row, counts(TP0,FP0,FN0,TN0), counts(TP,FP,FN,TN)) :-
    Model = model(Mu, SigmaSq, NF, Eps),
    gaussian_prob(Row, Mu, SigmaSq, NF, PVal),
    last(Row, Target),
    (   Target > 0.5            % expected anomaly
    ->  (   PVal > Eps
        ->  TP = TP0, FP = FP0, FN is FN0 + 1, TN = TN0   % false negative
        ;   TP is TP0 + 1, FP = FP0, FN = FN0, TN = TN0   % true positive
        )
    ;   (   PVal < Eps
        ->  TP = TP0, FP is FP0 + 1, FN = FN0, TN = TN0   % false positive
        ;   TP = TP0, FP = FP0, FN = FN0, TN is TN0 + 1   % true negative
        )
    ).

%% ---------- Histogram ----------

%% print_histogram(+Title, +Rows, +Index, +NumBins) is det.
%  Text-based histogram for a given feature column (1-indexed).
print_histogram(Title, Rows, Index, NumBins) :-
    maplist(nth1(Index), Rows, Vals),
    length(Bins0, NumBins),
    maplist(=(0), Bins0),
    foldl(bin_val(NumBins), Vals, Bins0, Bins),
    format('~n~w~n', [Title]),
    print_bins(Bins, 0).

bin_val(NumBins, Val, BinsIn, BinsOut) :-
    Idx is min(NumBins - 1, max(0, truncate(0.99 * Val * NumBins))),
    Idx1 is Idx + 1,
    nth1(Idx1, BinsIn, Old),
    New is Old + 1,
    replace_nth1(Idx1, BinsIn, New, BinsOut).

replace_nth1(1, [_|T], X, [X|T]).
replace_nth1(N, [H|T], X, [H|T2]) :-
    N > 1, N1 is N - 1,
    replace_nth1(N1, T, X, T2).

print_bins([], _).
print_bins([B|Bs], I) :-
    format('  ~w\t~w~n', [I, B]),
    I1 is I + 1,
    print_bins(Bs, I1).
