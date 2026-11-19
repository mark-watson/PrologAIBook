# Anomaly Detection

Anomaly detection is a machine learning technique for finding data points that differ significantly from the majority of observations. Unlike classification, where we train on balanced examples of each class, anomaly detection works well when we have many normal examples and only a few (or zero) anomalous ones. The algorithm learns what "normal" looks like, then flags anything that deviates from that profile.

This chapter implements a Gaussian anomaly detector in SWI-Prolog, ported from one of my Java programs. We apply it to the Wisconsin breast cancer dataset, where benign samples define the normal distribution and malignant samples show up as outliers.

## The Gaussian Approach

The core idea is simple. For each feature in the training data, we fit a Gaussian (bell curve) distribution by computing its mean `\mu`$ and variance `\sigma^2`$. At prediction time, we evaluate the Gaussian probability density function (PDF) for each feature of an unseen data point:

```$
p(x_i) = \frac{1}{\sqrt{2\pi}\sigma_i} \exp\left(-\frac{(x_i - \mu_i)^2}{2\sigma_i^2}\right)
```

If the average of these per-feature densities falls below a learned threshold `\epsilon`$ (epsilon), we flag the data point as an anomaly: it lies too far from the center of the normal distribution. (A density is not a probability and can exceed 1, as it does on this data.)

This approach has two appealing properties:

1. **One-class training.** We need mostly normal examples to build the model. An anomaly is anything "not normal". (We still need a few labeled anomalies to choose epsilon.)
2. **Interpretability.** Each feature contributes its own density, so we can see which features made a point look anomalous.

## The Training Pipeline

The pipeline has six stages:

1. Load the Wisconsin cancer CSV
2. Preprocess: scale, log-transform, normalise, remap target
3. Split into training, cross-validation, and test sets
4. Compute per-feature mean and variance from training data
5. Choose the epsilon threshold with the fewest errors on the cross-validation set
6. Evaluate precision, recall, and F1 on held-out test data

## Module Structure

Here is the module header:

```prolog
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
    search_epsilon/2,           % +PTPs, -Eps
    search_epsilon/5,           % +Start, +Step, +Steps, +PTPs, -Eps
    load_wisconsin_data/2,      % +MaxN, -Rows
    subsample_rows/3            % +Rows, +MaxN, -Sampled
]).

:- use_module(library(csv)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(random)).
```

We use four standard libraries: `csv` to read the data, `lists` and `apply` for list operations and higher-order predicates like `maplist/3` and `foldl/4`, and `random` to split the data.

## Loading the Data

The Wisconsin cancer dataset has 648 rows with 10 columns: 9 integer features (cell measurements from 1 to 10) and the class (2 = benign, 4 = malignant). The file is a CSV with no header.

```prolog
load_wisconsin_data(Rows) :-
    once(source_file(anomaly_detection:_, ThisFile)),
    file_directory_name(ThisFile, Dir),
    atomic_list_concat([Dir,
        '/../data/cleaned_wisconsin_cancer_data.csv'], Path),
    csv_read_file(Path, CsvRows,
                  [separator(0',), convert(true), arity(10)]),
    maplist(row_to_list, CsvRows, Rows).

%% load_wisconsin_data(+MaxN, -Rows) is det.
%  Load at most MaxN rows, keeping the class ratio (see
%  subsample_rows/3). Useful for quick experiments.
load_wisconsin_data(MaxN, Rows) :-
    load_wisconsin_data(AllRows),
    once(subsample_rows(AllRows, MaxN, Rows)).
```

`source_file/2` finds the module's own file, so the data path works from any directory. We wrap it in `once/1` because `source_file/2` gives one answer per predicate in the module, and we need only one.

The full pipeline on all 648 rows runs in well under a second, so we use all the data. For quick experiments, `load_wisconsin_data/2` loads a smaller stratified sample with `subsample_rows/3`:

```prolog
subsample_rows(Rows, MaxN, Sampled) :-
    length(Rows, Len),
    (   Len =< MaxN
    ->  Sampled = Rows
    ;   partition(is_malignant_row, Rows, Malignant, Benign),
        length(Malignant, LM), length(Benign, LB),
        % Keep the class ratio as closely as rounding allows; min/2
        % stops us asking for more malignant rows than exist.
        MaxB is round(MaxN * LB / Len),
        MaxM is min(LM, MaxN - MaxB),
        stratified_pick(Benign, MaxB, PickedB),
        stratified_pick(Malignant, MaxM, PickedM),
        append(PickedB, PickedM, Sampled)
    ).

is_malignant_row(Row) :- last(Row, 4).

% stratified_pick(+Rows, +N, -Picked): pick N rows, evenly spaced by
% index, so the pick is deterministic.
stratified_pick(Rows, N, Picked) :-
    length(Rows, Len),
    (   N >= Len
    ->  Picked = Rows
    ;   Stride is Len / N,
        Last is N - 1,
        numlist(0, Last, Offsets0),
        maplist(strides_index(Stride, Len), Offsets0, Indices0),
        maplist(nth0_pick(Rows), Indices0, Picked)
    ).

strides_index(Stride, Len, I, Idx) :-
    Idx is min(Len - 1, floor(I * Stride)).

nth0_pick(List, Idx, Elem) :- nth0(Idx, List, Elem).
```

The rows are split by class and each class is sampled in proportion, by picking evenly spaced rows, so the sample keeps the class ratio. `numlist(0, Last, ...)` with `Last = N - 1` gives exactly `N` offsets. When `MaxN` is at least the number of rows, the input comes back unchanged.

## Preprocessing

The raw features (integers from 1 to 10) need transforming before we fit Gaussians. The preprocessing matches the Java original:

```prolog
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
```

Four transformations happen in sequence:

1. **Scale by 0.1**: Maps integer features from [1, 10] to [0.1, 1.0].
2. **Log-transform**: `log(x + 1.2)` compresses the right tail, making the distribution more bell-shaped. The offset 1.2 prevents `log(0)`.
3. **Min-max normalise**: Rescales each row's features to [0, 1]. Note that this works *within* a row, not within a column: it keeps the shape of each sample's profile but discards its overall level. That choice comes from the Java original, and practice problem 2 asks you to test it.
4. **Target remapping**: The original target encodes benign as 2 and malignant as 4. The formula `(x - 2) * 0.5` maps these to 0.0 (normal) and 1.0 (anomaly).

`maplist/3` applies each transform to every feature. `normalise/4` takes `Min` and `Span` first, so `normalise(Min, Span)` can be passed to `maplist/3` as a partial application.

## Data Splitting

The split puts each row in one of four buckets: `train`, `cv` (cross-validation), `test`, or `skip`. We tag every row first and then filter by tag:

```prolog
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
```

The assignment logic mirrors the Java original:

- **60% chance** of going to training. A normal row (target < 0.5) goes there; an anomaly goes there only 10% of the time and is otherwise dropped. So the training set is mostly normal, which anomaly detection needs.
- **28% to cross-validation** and **12% to test**.

Tagging first keeps the code deterministic: `assign_row/2` gives each row exactly one tag, and `include/3` filters without leaving choice points. A recursive split written with `;` would leave a choice point for every row.

## Computing Statistics

From the training set we compute each feature's mean (`\mu`$) and variance (`\sigma^2`$):

```prolog
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
```

For each feature index, `feature_mean/4` collects the column with `maplist(nth1(FIdx), Rows, Vals)`, sums it, and divides by the number of rows. The variance follows the same pattern with squared differences from the mean:

```prolog
feature_var(Rows, N, Mu, FIdx, Var) :-
    nth1(FIdx, Mu, M),
    maplist(sq_diff(FIdx, M), Rows, Diffs),
    sumlist(Diffs, SumSq),
    Var is SumSq / N.

sq_diff(FIdx, M, Row, D) :-
    nth1(FIdx, Row, X),
    D is (X - M) * (X - M).
```

## The Gaussian PDF

The Gaussian probability density function (PDF) is the heart of the algorithm. For each feature of a data point, it measures how typical the value is under the learned distribution. The code walks three lists together (the row's features, the means, and the variances) and sums the per-feature densities:

```prolog
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
```

Walking the lists together (`[X|Xs], [M|Ms], [S2|Ss]`) costs O(1) per feature. Looking each value up with `nth1/3` would cost O(n) per lookup, since Prolog lists are linked lists.

The base case `gaussian_sum(_, _, _, _, 9, Acc, Acc)` stops after 9 features, skipping the target in position 10. The cut stops Prolog from trying the recursive clause as well.

Note: the Java original divides the summed PDF by the number of columns (10, including the class label) although only the 9 input features are summed. This implementation divides by `num_input_features` (9), which shifts the reported epsilon values slightly.

## Epsilon Search

Epsilon is the threshold between normal and anomalous. We choose it on the cross-validation set. First we compute the density for each CV row once:

```prolog
precompute_probs([], _, _, _, []).
precompute_probs([Row|Rows], Mu, SigmaSq, NF, [P-T|Rest]) :-
    gaussian_prob(Row, Mu, SigmaSq, NF, P),
    last(Row, T),
    precompute_probs(Rows, Mu, SigmaSq, NF, Rest).
```

This gives a list of `Density-Target` pairs. For each candidate epsilon, `count_errors/3` counts the mistakes:

- An **anomaly** (target > 0.5) with density **above** epsilon is a false negative (a missed anomaly).
- A **normal** point with density **below** epsilon is a false positive (a false alarm).

Which candidates should we try? A fixed grid is the obvious choice, and the module keeps one in `search_epsilon/5`. But a grid can stop too soon. The Java original swept 20 values from 0.001 to 0.951, and on this data that grid picked its largest value, 0.951: the best threshold was beyond the end of the grid, because densities here range up to about 1.4.

The default `search_epsilon/2` avoids the problem. The error count only changes when epsilon crosses one of the CV densities, so the midpoints between neighbouring densities are the only candidates worth trying:

```prolog
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
%  Data-driven search: the only thresholds that change the error
%  count lie between two neighbouring CV probabilities, so we try
%  the midpoint of each neighbouring pair. Unlike a fixed grid, this
%  cannot miss the best threshold by stopping too early.
search_epsilon(PTPs, BestEps) :-
    pairs_keys(PTPs, Probs),
    msort(Probs, Sorted),
    findall(E, (nextto(A, B, Sorted), E is (A + B) / 2), Candidates),
    maplist(count_errors(PTPs), Candidates, ErrorCounts),
    min_list(ErrorCounts, MinErr),
    nth0(BestIdx, ErrorCounts, MinErr), !,
    nth0(BestIdx, Candidates, BestEps).
```

`nextto(A, B, Sorted)` enumerates each pair of neighbouring densities. The epsilon with the fewest CV errors wins. On the full dataset this search makes 15 CV errors where the old grid made 19.

## Putting It Together

The `train_model/2` predicate wraps a pure computation and a report printer:

```prolog
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
```

`compute_model/2` returns a dict of results and prints nothing. `report_model/1` prints the report. `train_model/2` does both.

The model is the term `model(Mu, SigmaSq, NF, BestEps)`, which holds everything needed to classify a new point:

```prolog
is_anomaly(model(Mu, SigmaSq, NF, Eps), Row) :-
    gaussian_prob(Row, Mu, SigmaSq, NF, P),
    P < Eps.
```

This succeeds if the row is an anomaly and fails otherwise, which fits Prolog's success and failure semantics.

## Evaluation

`evaluate_model/2` computes the usual classification metrics on the test set:

```prolog
evaluate_model(Model, TestRows) :-
    foldl(classify_row(Model), TestRows,
          counts(0,0,0,0), counts(TP,FP,FN,TN)),
    ...
```

The accumulator is a `counts(TP, FP, FN, TN)` term that `foldl/4` passes from row to row. From the final counts:

- **Precision** = TP / (TP + FP): of the points we called anomalies, how many were?
- **Recall** = TP / (TP + FN): of the real anomalies, how many did we catch?
- **F1** = 2 * Precision * Recall / (Precision + Recall): the harmonic mean of the two.

## Running the Example

{linenos=off}
~~~~~~~~
$ cd source-code/anomaly_detection
$ make run
=== Running anomaly detection on Wisconsin cancer data ===
Split: 263 train, 190 cv, 71 test

**** Best epsilon value = 1.045599

 -- number of test examples = 71
 -- true positives  = 21
 -- false positives = 1
 -- false negatives = 6
 -- true negatives  = 43
 -- precision = 0.954545
 -- recall    = 0.777778
 -- F1        = 0.857143
~~~~~~~~

`compute_model/2` seeds the random number generator with `set_random(seed(42))`, so every run gives the output above. Precision is high (one false alarm in 22 alerts), while recall is lower: 6 of the 27 malignant samples slip through. For cancer screening, a missed case costs far more than a false alarm, so in practice you would choose a higher epsilon and accept more false alarms. Practice problem 1 explores this.

Run the tests with:

{linenos=off}
~~~~~~~~
$ make test
% All 13 tests passed in 0.051 seconds (0.044 cpu)
~~~~~~~~

## Prolog-Specific Design Decisions

**Determinism.** The hardest part of the port was controlling backtracking. Several predicates leave choice points:

- `source_file/2` gives one answer per predicate in the module
- Disjunction (`;`) inside recursive predicates leaves choicepoints at every branch
- `nth0/3` with an unbound index generates solutions lazily

We handle these with `once/1`, cuts after `nth0/3`, and tagging then filtering in `split_data/4`.

**Lists vs. arrays.** Prolog lists are linked lists, so `nth1/3` costs O(n) per access. Walking the row, means, and variances together by pattern matching costs O(1) per feature.

**Precomputed densities.** The Java version recomputes the PDF for every epsilon candidate. We compute each CV density once, so trying a candidate only compares numbers.

**Data-driven thresholds.** Trying the midpoints between sorted CV densities finds the best threshold on the CV set, with no grid range or step size to tune. With about 190 CV rows, that is about 190 candidates, which takes milliseconds.

## Wrap Up

This example shows that statistical machine learning fits well in Prolog. The detector uses only standard SWI-Prolog libraries and runs on the full dataset in well under a second. Its techniques (`maplist` for transforms, `foldl` for accumulators, walking lists together, and tag-then-filter splitting) carry over to other numerical code in Prolog.

## Optional Practice Problems

1. **Weighting Missed Cases**: Change `count_errors/3` to take a cost for false negatives and a cost for false positives, and choose epsilon by minimum total cost. How do precision and recall change when a missed malignant case costs ten times a false alarm?
2. **Normalise by Column**: Change `preprocess/2` to min-max normalise each feature *column* across the training set instead of each row. Does F1 improve?
3. **Which Feature?**: Write `explain_anomaly(+Model, +Row, -Ranked)` that lists the features sorted by their density, lowest first, so a user can see why a row was flagged.
