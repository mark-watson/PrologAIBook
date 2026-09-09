# Anomaly Detection

Anomaly detection is a machine learning technique for finding data points that differ significantly from the majority of observations. Unlike classification — where we train on balanced examples of each class — anomaly detection works well when we have many normal examples and only a few (or zero) anomalous ones. The algorithm learns what "normal" looks like, then flags anything that deviates from that profile.

This chapter implements a Gaussian anomaly detector in SWI-Prolog, ported from a Java implementation. We apply it to the Wisconsin Diagnostic Breast Cancer dataset, where benign samples define the normal distribution and malignant samples appear as statistical outliers.

## The Gaussian Approach

The core idea is straightforward. For each feature in the training data, we fit a Gaussian (bell curve) distribution by computing its mean `\mu`$ and variance `\sigma^2`$. At prediction time, we evaluate the Gaussian probability density function (PDF) for each feature of an unseen data point:

{$$}
p(x_i) = \frac{1}{\sqrt{2\pi}\sigma_i} \exp\left(-\frac{(x_i - \mu_i)^2}{2\sigma_i^2}\right)
{/$$}

If the average per-feature probability falls below a learned threshold `\epsilon`$ (epsilon), the data point is flagged as anomalous — it lies too far from the centre of the normal distribution.

This approach has two appealing properties:

1. **One-class training.** We only need normal examples to build the model. Anomalies are defined implicitly as "not normal."
2. **Interpretability.** Each feature contributes an independent probability, so we can see which features drove the anomaly classification.

## The Training Pipeline

The complete pipeline has six stages. Here is an overview before we walk through each one:

1. Load and subsample the Wisconsin cancer CSV
2. Preprocess: scale, log-transform, normalise, remap target
3. Split into training, cross-validation, and test sets
4. Compute per-feature mean and variance from training data
5. Search for the best epsilon threshold via cross-validation
6. Evaluate precision, recall, and F1 on held-out test data

## Module Structure

The module exports the full API:

{lang="prolog",linenos=off}
~~~~~~~~
:- module(anomaly_detection, [
    load_wisconsin_data/1,      % -Rows
    preprocess/2,               % +RawRows, -Processed
    split_data/4,               % +Rows, -Train, -CV, -Test
    compute_mu/3,               % +Train, +NF, -Mu
    compute_sigma_sq/4,         % +Train, +NF, +Mu, -SigmaSq
    compute_model/2,            % +Rows, -Report(dict)
    report_model/1,             % +Report(dict)
    train_model/2,              % +Rows, -Model
    is_anomaly/2,               % +Model, +Row
    evaluate_model/2,           % +Model, +TestRows
    print_histogram/4,          % +Title, +Rows, +Index, +NumBins
    search_epsilon/5,           % +Start, +Step, +Steps, +PTPs, -Eps
    subsample_rows/3            % +Rows, +MaxN, -Sampled
]).

:- use_module(library(csv)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(random)).
~~~~~~~~

We rely on four standard SWI-Prolog libraries: `csv` for reading the dataset, `lists` and `apply` for list operations and higher-order predicates like `maplist/3` and `foldl/4`, and `random` for data splitting.

## Loading and Subsampling

The Wisconsin cancer dataset has 648 rows with 10 columns: 9 integer features (cell measurements) and 1 target class (2 = benign, 4 = malignant). The data file ships as a headerless CSV.

{lang="prolog",linenos=off}
~~~~~~~~
load_wisconsin_data(Rows) :-
    once(source_file(anomaly_detection:_, ThisFile)),
    file_directory_name(ThisFile, Dir),
    atomic_list_concat([Dir,
        '/../data/cleaned_wisconsin_cancer_data.csv'], Path),
    csv_read_file(Path, CsvRows,
                  [separator(0',), convert(true), arity(10)]),
    maplist(row_to_list, CsvRows, AllRows),
    once(subsample_rows(AllRows, 200, Rows)).
~~~~~~~~

The `source_file/2` call locates the module's own source directory, making the data path relative and portable. We wrap it in `once/1` because `source_file/2` returns one solution per exported predicate — without the cut, Prolog would backtrack through all of them.

We subsample to approximately 200 rows to keep runtime fast in an interpreted language. The `subsample_rows/3` predicate takes a stratified subsample:

{lang="prolog",linenos=off}
~~~~~~~~
subsample_rows(Rows, MaxN, Sampled) :-
    length(Rows, Len),
    (   Len =< MaxN
    ->  Sampled = Rows
    ;   partition(is_malignant_row, Rows, Malignant, Benign),
        length(Malignant, LM), length(Benign, LB),
        % Preserve the class ratio as closely as integer rounding
        % allows (LM is kept as the explicitly-named total for the
        % minority class; referenced via min/3 below so the split can
        % never ask for more anomalies than exist).
        MaxB is round(MaxN * LB / Len),
        MaxM is min(LM, MaxN - MaxB),
        stratified_pick(Benign, MaxB, PickedB),
        stratified_pick(Malignant, MaxM, PickedM),
        append(PickedB, PickedM, Sampled)
    ).

is_malignant_row(Row) :- last(Row, 4).

% stratified_pick(+Rows, +N, -Picked) — pick N rows, evenly spaced by
% index so the pick is deterministic given a seeded RNG.
stratified_pick(Rows, N, Picked) :-
    length(Rows, Len),
    (   N >= Len
    ->  Picked = Rows
    ;   Stride is Len / N,
        numlist(0, N, Offsets0),
        maplist(strides_index(Stride, Len), Offsets0, Indices0),
        maplist(nth0_pick(Rows), Indices0, Picked)
    ).

strides_index(Stride, Len, I, Idx) :-
    Idx is min(Len - 1, floor(I * Stride)).

nth0_pick(List, Idx, Elem) :- nth0(Idx, List, Elem).
~~~~~~~~

Rows are split by class label (2 = benign, 4 = malignant) and each class is sampled proportionally via evenly-spaced index picks, so the subsample preserves the class ratio by construction. When `MaxN` is at least the row count, the input is returned unchanged, which keeps every malignant row.

## Preprocessing

The raw integer features (ranging 1–10) need to be transformed before Gaussian modelling. The preprocessing pipeline matches the Java original:

{lang="prolog",linenos=off}
~~~~~~~~
preprocess_row([F1, F2, F3, F4, F5, F6, F7, F8, F9, Target], Out) :-
    Features = [F1, F2, F3, F4, F5, F6, F7, F8, F9],
    maplist(scale01, Features, Scaled),
    maplist(log_transform, Scaled, Logged),
    min_list(Logged, Min), max_list(Logged, Max),
    Span is Max - Min,
    (   Span =:= 0
    ->  maplist(=( 0.0), Normed)
    ;   maplist(normalise(Min, Span), Logged, Normed)
    ),
    TargetOut is (Target - 2) * 0.5,
    Normed = [N1, N2, N3, N4, N5, N6, N7, N8, N9],
    Out = [N1, N2, N3, N4, N5, N6, N7, N8, N9, TargetOut].

scale01(X, Y) :- Y is X * 0.1.
log_transform(X, Y) :- Y is log(X + 1.2).
normalise(Min, Span, X, Y) :- Y is (X - Min) / Span.
~~~~~~~~

Four transformations happen in sequence:

1. **Scale by 0.1** — Maps integer features from [1, 10] to [0.1, 1.0].
2. **Log-transform** — `log(x + 1.2)` compresses the right tail, making the distribution more bell-shaped. The offset 1.2 prevents `log(0)`.
3. **Min-max normalise** — Rescales each row's features to [0, 1]. This per-row normalisation removes scale differences between samples.
4. **Target remapping** — The original target encodes benign as 2 and malignant as 4. The formula `(x - 2) * 0.5` maps these to 0.0 (normal) and 1.0 (anomaly).

Notice how `maplist/3` applies each transform in a declarative, functional style. The `normalise/4` predicate takes `Min` and `Span` as its first two arguments — a partial application pattern that works naturally with `maplist`.

## Data Splitting

The split assigns each row to one of four buckets: `train`, `cv` (cross-validation), `test`, or `skip`. We use a tag-then-filter strategy for full determinism:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

The assignment logic mirrors the Java original:

- **60% chance** of going to training — but only if the row is normal (target < 0.5). Anomalous rows are mostly skipped, with ~10% leaking through. This ensures the training set is dominated by normal examples, which is the key requirement for anomaly detection.
- **28% to cross-validation**, **12% to test**.
- Skipped anomalies are simply dropped.

The tag-then-filter pattern deserves comment. An earlier version used direct recursive splitting with Prolog disjunctions (`;`), but this left choicepoints that caused backtracking across the entire pipeline. The `maplist/assign_row` approach is fully deterministic — each row gets exactly one tag, and `include/3` partitions without any choicepoints.

## Computing Statistics

With the training set isolated, we compute per-feature mean (`\mu`$) and variance (`\sigma^2`$):

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

For each feature index, `feature_mean/4` extracts all values via `maplist(nth1(FIdx), Rows, Vals)`, sums them, and divides by the number of training examples. The variance computation follows the same pattern, using squared differences from the mean:

{lang="prolog",linenos=off}
~~~~~~~~
feature_var(Rows, N, Mu, FIdx, Var) :-
    nth1(FIdx, Mu, M),
    maplist(sq_diff(FIdx, M), Rows, Diffs),
    sumlist(Diffs, SumSq),
    Var is SumSq / N.

sq_diff(FIdx, M, Row, D) :-
    nth1(FIdx, Row, X),
    D is (X - M) * (X - M).
~~~~~~~~

## The Gaussian PDF

The Gaussian Probability Density Function (PDF) is the heart of the algorithm. For each feature in a data point, we compute how likely that value is under the learned normal distribution. The implementation walks three lists in parallel — the row's features, the means, and the variances — accumulating the sum of per-feature PDF values:

{lang="prolog",linenos=off}
~~~~~~~~
gaussian_prob(Row, Mu, SigmaSq, NF, P) :-
    sqrt_2_pi(S2P),
    gaussian_sum(Row, Mu, SigmaSq, S2P, 0, 0.0, Sum),
    P is Sum / NF.

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
~~~~~~~~

The parallel list walk (`[X|Xs], [M|Ms], [S2|Ss]`) is a deliberate performance choice. An earlier version used `nth1/3` to extract each feature by index — but `nth1` is O(n) on linked lists, and calling it 3 times per feature × 9 features × every row added up badly. Walking the lists in parallel is O(1) per element.

The base case `gaussian_sum(_, _, _, _, 9, Acc, Acc)` stops after 9 features, skipping the target column at position 10. The cut prevents backtracking into the recursive clause.

Note: the Java original divides the summed PDF by the number of columns (10, including the class label) although only the 9 input features are summed. This implementation divides by `num_input_features` (9), which shifts the reported epsilon values slightly.

## Epsilon Search

Epsilon is the threshold that separates normal from anomalous. We find the best value by grid search over the cross-validation set. The key optimisation is to precompute the Gaussian probability for each CV row once, then sweep epsilon across the precomputed values:

{lang="prolog",linenos=off}
~~~~~~~~
precompute_probs([], _, _, _, []).
precompute_probs([Row|Rows], Mu, SigmaSq, NF, [P-T|Rest]) :-
    gaussian_prob(Row, Mu, SigmaSq, NF, P),
    last(Row, T),
    precompute_probs(Rows, Mu, SigmaSq, NF, Rest).
~~~~~~~~

This creates a list of `Probability-Target` pairs. The epsilon sweep then counts errors without recomputing any PDFs:

{lang="prolog",linenos=off}
~~~~~~~~
%% search_epsilon(+Start, +Step, +Steps, +PTPs, -BestEps) is det.
%  Grid search: Steps candidate epsilon values, Start + Step*I.
search_epsilon(Start, Step, Steps, PTPs, BestEps) :-
    LastStep is Steps - 1,
    numlist(0, LastStep, StepIdxs),
    maplist(grid_epsilon(Start, Step), StepIdxs, Epsilons),
    maplist(count_errors(PTPs), Epsilons, ErrorCounts),
    min_list(ErrorCounts, MinErr),
    nth0(BestIdx, ErrorCounts, MinErr), !,
    nth0(BestIdx, Epsilons, BestEps).

grid_epsilon(Start, Step, I, Eps) :-
    Eps is Start + Step * I.

%% search_epsilon(+PTPs, -BestEps) is det.
%  Backwards-compatible default grid: 20 steps starting at 0.001 in
%  steps of 0.05 (the original hard-coded sweep).
search_epsilon(PTPs, BestEps) :-
    search_epsilon(0.001, 0.05, 20, PTPs, BestEps).
~~~~~~~~

We test 20 epsilon values from 0.001 to 0.951, spaced at 0.05 intervals. For each epsilon, an error occurs when:

- An **anomaly** (target > 0.5) has probability **above** epsilon — a false negative (missed anomaly)
- A **normal** point (target <= 0.5) has probability **below** epsilon — a false positive (false alarm)

The epsilon with the fewest total cross-validation errors wins.

## Putting It Together

The `train_model/2` predicate wraps a pure computation and a report printer:

{lang="prolog",linenos=off}
~~~~~~~~
%% compute_model(+Rows, -Result) is det.
%  Pure computation: preprocess, split, fit statistics, search epsilon,
%  evaluate.  Returns a dict of results:
%    _{model: model(Mu,SigmaSq,NF,Eps), split: split(NT,NCV,NTest),
%      metrics: metrics(TP,FP,FN,TN,Precision,Recall,F1)}
compute_model(Rows, Result) :-
    % Seeded so the pipeline is reproducible end-to-end.
    set_random(seed(42)),
    preprocess(Rows, Processed),
    once(split_data(Processed, Train, CV, Test)),
    length(Train, NTrain), length(CV, NCV), length(Test, NTest),
    num_input_features(NF),
    compute_mu(Train, NF, Mu),
    compute_sigma_sq(Train, NF, Mu, SigmaSq),
    precompute_probs(CV, Mu, SigmaSq, NF, CVProbs),
    once(search_epsilon(CVProbs, BestEps)),
    Model = model(Mu, SigmaSq, NF, BestEps),
    eval_counts(Model, Test, metrics(TP, FP, FN, TN, Prec, Rec, F1),
        NTest),
    Result = _{ model: Model,
                split: split(NTrain, NCV, NTest),
                metrics: metrics(TP, FP, FN, TN, Prec, Rec, F1) }.

%% report_model(+Result) is det.
%  Print the human-readable report for a computed result dict.
report_model(Result) :-
    Result.split = split(NTrain, NCV, NTest),
    Result.model = model(_, _, _, BestEps),
    Result.metrics = metrics(TP, FP, FN, TN, Precision, Recall, F1),
    format('Split: ~w train, ~w cv, ~w test~n', [NTrain, NCV, NTest]),
    format('~n**** Best epsilon value = ~6f~n', [BestEps]),
    format('~n -- number of test examples = ~w~n', [NTest]),
    format(' -- true positives  = ~w~n', [TP]),
    format(' -- false positives = ~w~n', [FP]),
    format(' -- false negatives = ~w~n', [FN]),
    format(' -- true negatives  = ~w~n', [TN]),
    format(' -- precision = ~6f~n', [Precision]),
    format(' -- recall    = ~6f~n', [Recall]),
    format(' -- F1        = ~6f~n', [F1]).

%% train_model(+Rows, -Model) is det.
%  Backwards-compatible wrapper: compute then report.
train_model(Rows, Model) :-
    compute_model(Rows, Result),
    report_model(Result),
    Model = Result.model, !.
~~~~~~~~

`compute_model/2` is pure: it returns a result dict and prints nothing. `report_model/1` prints the report. `train_model/2` composes the two for backward compatibility.

The model is a compound term `model(Mu, SigmaSq, NF, BestEps)` that bundles everything needed for prediction. After training, you can classify new data points with:

{lang="prolog",linenos=off}
~~~~~~~~
is_anomaly(model(Mu, SigmaSq, NF, Eps), Row) :-
    gaussian_prob(Row, Mu, SigmaSq, NF, P),
    P < Eps.
~~~~~~~~

This succeeds (returns `true`) if the row is an anomaly, and fails otherwise — a natural fit for Prolog's success/failure semantics.

## Evaluation

The `evaluate_model/2` predicate computes standard binary classification metrics on the test set:

{lang="prolog",linenos=off}
~~~~~~~~
evaluate_model(Model, TestRows) :-
    foldl(classify_row(Model), TestRows,
          counts(0,0,0,0), counts(TP,FP,FN,TN)),
    ...
~~~~~~~~

The accumulator is a `counts(TP, FP, FN, TN)` term that threads through the fold, updating one counter per test row. The final counts yield:

- **Precision** = TP / (TP + FP) — of the points we called anomalies, how many actually were?
- **Recall** = TP / (TP + FN) — of the actual anomalies, how many did we catch?
- **F1** = 2 * Precision * Recall / (Precision + Recall) — harmonic mean of precision and recall.

## Running the Example

{linenos=off}
~~~~~~~~
$ cd source-code/anomaly_detection
$ make run
=== Running anomaly detection on Wisconsin cancer data ===
Split: 88 train, 56 cv, 22 test

**** Best epsilon value = 0.951000

 -- number of test examples = 22
 -- true positives  = 5
 -- false positives = 0
 -- false negatives = 3
 -- true negatives  = 14
 -- precision = 1.000000
 -- recall    = 0.625000
 -- F1        = 0.769231
~~~~~~~~

The pipeline is seeded via `set_random(seed(42))` and the subsample is a deterministic evenly-spaced stratified pick, so the output above is reproducible run-to-run. Precision is high (the model rarely cries wolf), while recall is lower, so some anomalies slip through.

Run the tests with:

{linenos=off}
~~~~~~~~
$ make test
% All 9 tests passed in 0.025 seconds (0.022 cpu)
~~~~~~~~

## Prolog-Specific Design Decisions

**Determinism.** The most challenging aspect of this port was controlling Prolog's backtracking. Several predicates naturally produce choicepoints:

- `source_file/2` returns one solution per exported predicate
- Disjunction (`;`) inside recursive predicates leaves choicepoints at every branch
- `nth0/3` with an unbound index generates solutions lazily

We addressed these with `once/1` wrappers and a tag-then-filter strategy for `split_data`. The final `!` in `train_model` commits to the first successful training run.

**Lists vs. arrays.** Prolog lists are linked lists — `nth1/3` is O(n) per access. The Gaussian PDF needs to access three parallel lists (row, means, variances) for each of 9 features. Using `nth1` would mean 27 * O(n) lookups per row. Instead, we walk the three lists in parallel via pattern matching (`[X|Xs], [M|Ms], [S2|Ss]`), giving O(1) per element. This alone gave us a large speedup.

**Precomputed probabilities.** The Java version recomputes the Gaussian PDF for every epsilon candidate. In Prolog, where arithmetic is slower than in the JVM, we precompute all PDF values before the epsilon sweep. The 20-step grid search then just compares precomputed floats to the epsilon threshold — pure arithmetic with no list traversal.

**Subsampling.** The full 648-row dataset with 200 epsilon steps would be impractical in interpreted Prolog. We subsample to ~200 rows and use 20 epsilon steps, reducing the workload by roughly 65x. The model quality remains strong thanks to the class-balanced sampling and the dataset's clear separation between benign and malignant clusters.

## Wrap Up

This example demonstrates that statistical machine learning algorithms can be implemented naturally in Prolog. The Gaussian anomaly detector uses only standard SWI-Prolog libraries — no external packs — and fits comfortably into Prolog's declarative style. The key techniques — `maplist` for transforms, `foldl` for accumulators, parallel list walking for performance, and tag-then-filter for deterministic splitting — are broadly useful patterns for any numerical computation in Prolog.

## Optional Practice Problems

1. **Sensitivity Threshold**: In the `anomaly_detection` project, modify the thresholding logic to accept a dynamic sensitivity parameter that increases or decreases the strictness of the anomaly classification.
2. **Out-of-Order Sequence Check**: Write a predicate in `anomaly.pl` that flags sequences of log events that violate a predefined transaction state transitions order.
