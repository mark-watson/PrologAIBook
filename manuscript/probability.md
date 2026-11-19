# Probability

Probability theory is the mathematics of uncertainty. Frequentists treat a probability as the long-run frequency of a repeatable event. Bayesians treat it as a degree of belief: Bayes' Theorem updates a prior belief with new evidence to give a posterior belief, which works even with little data.

Probability models describe correlation, not cause. Observed data can tell us how often two things occur together, but to predict what happens when we *intervene* (change one thing on purpose) we need causal models, such as structural causal models. That takes different mathematics from computing the probability of what we observe.

The source code for this chapter is in the directory **source-code/probability**.

## Words of Warning

Professor Carissa Véliz says in her book "Prophecy" that when you read a percentage you should first ask yourself if you are being told a fact or a prediction. If a percentage is a prediction, consciously tag it as "not a fact."

Numbers look precise, and that is the danger of mixing the two. A percentage that records a past measurement can be checked. A percentage that predicts is the output of a model, and it depends on the model's priors, its training data, and its assumptions. Tagging a prediction as "not a fact" makes you ask questions about it: What does the model not see? How would it cope with cases unlike its training data?

## Glossary of Terms

Here are the statistical terms this chapter uses.

**Prior (prior probability)**: Your initial belief about how likely a hypothesis is *before* you observe any new evidence. In the medical example below, the prior probability of disease is the prevalence rate (0.1 %). Priors can be informative (based on domain knowledge) or uninformative (deliberately vague).

**Posterior (posterior probability)**: Your updated belief about a hypothesis *after* incorporating observed evidence via Bayes' Theorem: P(Hypothesis | Data). In the medical example, the posterior probability of disease given a positive test is approximately 1.9 %.

**Likelihood**: The probability of observing the evidence *assuming a specific hypothesis is true*: P(Evidence | Hypothesis). In the medical example, the likelihood of a positive test result given disease is 0.99 (the sensitivity).

**Marginal likelihood (evidence)**: The total probability of the observed evidence across all hypotheses: Σ P(Evidence | H) · P(H). It acts as the normalising constant in Bayes' Theorem.

**Bayes' Theorem**: The mathematical rule connecting prior, likelihood, and posterior: P(H | E) = P(E | H) · P(H) / P(E).

**Maximum a posteriori (MAP)**: The hypothesis with the highest posterior probability, the Bayesian "best guess." `maximum_a_posteriori/2` breaks ties deterministically by standard term order, so among hypotheses with equal maximum probability the `@<`-smallest wins.

**Prevalence (base rate)**: The proportion of a population that has a particular condition. When the base rate is very low, even a highly accurate test produces many false positives relative to true positives.

**Sensitivity (true-positive rate)**: The probability that a test correctly identifies a positive case: P(Test+ | Condition+).

**Specificity (true-negative rate)**: The probability that a test correctly identifies a negative case: P(Test− | Condition−).

**False-positive rate**: The probability that a test incorrectly flags a healthy individual as positive: P(Test+ | Condition−).

**Positive predictive value (PPV)**: Among everyone who tested positive, the fraction who actually have the condition: TP / (TP + FP).

**Z-score (standard score)**: The number of standard deviations a data point lies from the mean: z = (x − μ) / σ.

**P-value**: The probability of observing data *at least as extreme* as what was measured, *assuming the null hypothesis is true*. Crucially, the p-value is **not** the probability that the hypothesis is true or false.

**Null hypothesis (H₀)**: The default assumption of "no effect" that a frequentist test tries to reject.

**Chi-squared test**: A test that compares observed counts with expected counts using Σ (O − E)² / E. A *goodness-of-fit* test compares counts with a given distribution. A *test of independence* asks whether two variables in a table of counts are related.

**Confidence interval (CI)**: A frequentist range estimate. A 95 % CI means: if you repeated the experiment many times, 95 % of the computed intervals would contain the true parameter.

**Wilson score interval**: A method for computing a confidence interval for a binomial proportion that is more accurate than the simple Wald interval, especially for small samples or proportions near 0 or 1.

**Pearson correlation coefficient (r)**: A measure of linear association between two variables, ranging from −1 to +1. It measures *association*, not causation.

**Spearman rank correlation (ρ)**: A non-parametric measure of monotonic association. More robust to outliers than Pearson-r.

## A SWI-Prolog Library to Explore Probability

### Design

The library provides four modules spanning both Bayesian and Frequentist reasoning:

1. **Bayesian Inference (`bayes.pl`)**: Model construction from hypothesis-probability pairs, Bayes' Theorem updates via `update/4`, posterior queries, and MAP estimation.

2. **Correlation helpers (`correlation.pl`)**: Pearson-r, Spearman rank correlation, and correlation matrices. These functions explicitly measure *association*, not causation.

3. **Frequentist Statistics (`frequentist.pl`)**: z-tests, chi-squared tests (goodness of fit and independence), and Wilson confidence intervals.

4. **Worked examples**: `medical_example.pl` demonstrates Bayesian reasoning on a screening test; `frequentist_demo.pl` revisits the same scenario from the frequentist standpoint.

### File layout

~~~~~~~~
probability/
├── prolog/
│   ├── bayes.pl              # Bayesian toolkit
│   ├── correlation.pl        # Correlation toolkit
│   ├── frequentist.pl        # Frequentist toolkit
│   ├── medical_example.pl    # Bayesian worked example
│   └── frequentist_demo.pl   # Frequentist worked example
├── tests/
│   └── test_probability.pl
├── load.pl
├── Makefile
└── README.md
~~~~~~~~

### Running the examples

{linenos=off}
~~~~~~~~
$ cd source-code/probability
$ make run
=== Running Bayesian medical screening example ===

=== Bayesian Analysis: Medical Screening Test ===
Prior probabilities:
  P(disease) = 0.0010  (0.10 %)
  P(healthy) = 0.9990  (99.90 %)

After a POSITIVE test result:
  P(disease) = 0.0194  (1.94 %)
  P(healthy) = 0.9806  (98.06 %)

MAP hypothesis: healthy

Key insight: despite 99% sensitivity, a positive test
only yields about 1.9% probability of disease because the
disease is so rare (0.1% prevalence).

=== Correlation Analysis (N = 100000) ===
Pearson r(test-result, disease) = 0.1319

Correlation is real but modest. Individual prediction
requires Bayesian reasoning with the base rate.

=== Done. ===
~~~~~~~~

## Walking Through the Bayesian Code

### The Bayes Model

The core data structure is a normalised list of `Hypothesis-Probability` pairs. The constructor makes the priors sum to one:

```prolog
make_bayes_model(PriorPairs, Model) :-
    maplist(pair_value, PriorPairs, Priors),
    sumlist(Priors, Total),
    (   Total =:= 0
    ->  throw(error(all_priors_zero,
        'All priors are zero, so they cannot be normalised.'))
    ;   maplist(normalise_pair(Total), PriorPairs, Model)
    ).

pair_value(_-V, V).

normalise_pair(Total, H-P, H-NP) :-
    NP is P / Total.
```

Prolog's `-` operator makes pairs: `disease-0.001` is the term `-(disease, 0.001)`. `maplist(normalise_pair(Total), ...)` uses partial application: `normalise_pair(Total)` has its first argument bound, and `maplist/3` supplies the other two.

### Updating with Evidence

The `update/4` predicate applies Bayes' Theorem. It takes the likelihood as a predicate argument, declared with `meta_predicate`:

```prolog
:- meta_predicate update(+, +, 2, -).

%% update(+Model, +Evidence, :LikelihoodPred, -Updated)
%% LikelihoodPred is a predicate of arity 2: LikelihoodPred(Hypothesis,
%% P)
%% that binds P to P(Evidence | Hypothesis) when called.
%% Evidence is passed for documentation but not used directly.
%% Example: update(Model, positive, my_lik, Updated)
%%   where my_lik(disease, 0.99) and my_lik(healthy, 0.05) are defined.
update(Model, _Evidence, LikelihoodPred, Updated) :-
    maplist(unnormalised_posterior(LikelihoodPred), Model,
        Unnormalised),
    maplist(pair_value, Unnormalised, UnnormProbs),
    sumlist(UnnormProbs, Marginal),
    (   Marginal =:= 0.0
    ->  throw(error(zero_marginal,
                    'Marginal likelihood is zero: the evidence is impossible under all hypotheses.'))
    ;   maplist(normalise_pair(Marginal), Unnormalised, Updated)
    ).
unnormalised_posterior(LikelihoodPred, H-Prior, H-UPost) :-
    call(LikelihoodPred, H, Lik),
    UPost is Lik * Prior.
```

The key is `call(LikelihoodPred, H, Lik)`, which calls the likelihood predicate with the hypothesis and binds the likelihood. This is Prolog's usual higher-order pattern. The `meta_predicate` declaration makes the call find the likelihood predicate in the caller's module, even though `update/4` lives in the `bayes` module.

`Marginal` is the denominator in Bayes' Theorem. Dividing by it makes the posteriors sum to one.

### The Medical Screening Example

The worked example makes Bayes' Theorem concrete. A rare disease affects 0.1 % of the population. A screening test has 99 % sensitivity and a 5 % false-positive rate. If a patient tests positive, what is the probability they are sick?

```prolog
prevalence(0.001).
sensitivity(0.99).
false_positive_rate(0.05).

likelihood(disease, P) :- sensitivity(P).
likelihood(healthy, P) :- false_positive_rate(P).

run_bayesian_analysis :-
    prevalence(Prev),
    Healthy is 1.0 - Prev,
    make_bayes_model([disease-Prev, healthy-Healthy], Prior),
    update(Prior, positive_test, likelihood, Updated),
    ...
```

The likelihood predicate has one clause per hypothesis, and Prolog's pattern matching picks the right one. Passing the name `likelihood` to `update/4` lets the Bayes engine call it for each hypothesis.

The answer is about **1.9 %**. Check it by counting: out of 100,000 people, about 100 are sick and 99 of them test positive. Of the 99,900 healthy people, 5 %, or about 4,995, also test positive. So only 99 of about 5,094 positive results are real: 1.9 %.

### Correlation Analysis

The example also generates a synthetic population and computes the Pearson correlation between test results and disease status:

```prolog
generate_synthetic_population(N, Tests, Diagnoses) :-
    prevalence(Prev), sensitivity(Sens), false_positive_rate(FPR),
    length(Tests, N), length(Diagnoses, N),
    maplist(simulate_individual(Prev, Sens, FPR), Tests, Diagnoses).

simulate_individual(Prev, Sens, FPR, Test, Diag) :-
    random(R1),
    (   R1 < Prev
    ->  Diag = 1.0, random(R2), (R2 < Sens -> Test = 1.0 ; Test = 0.0)
    ;   Diag = 0.0, random(R3), (R3 < FPR  -> Test = 1.0 ; Test = 0.0)
    ).
```

The Pearson r is positive but modest (about 0.13). A real association in the population does not give reliable predictions for individuals. For that you need Bayesian reasoning with the base rate.

## The Correlation Module

The Pearson correlation coefficient measures linear association. The code uses `maplist/4` to compute the products of deviations:

```prolog
pearson_r(Xs, Ys, R) :-
    length(Xs, N),
    length(Ys, N),   % assert equal length
    list_mean(Xs, MX),
    list_mean(Ys, MY),
    list_std_dev(Xs, SX),
    list_std_dev(Ys, SY),
    (   (SX =:= 0 ; SY =:= 0)
    ->  R = 0.0
    ;   maplist(cross_dev(MX, MY), Xs, Ys, Prods),
        sumlist(Prods, SumProd),
        R is SumProd / (N * SX * SY)
    ).

cross_dev(MX, MY, X, Y, P) :-
    P is (X - MX) * (Y - MY).
```

The Spearman rank correlation replaces each value with its rank (tied values share the average rank) and then computes Pearson r on the ranks. This makes it robust to outliers, and it detects any monotonic relationship, not just a linear one.

## Frequentists vs. Bayesians

Frequentists and Bayesians disagree on what a probability *is*.

### What probability means

| | Frequentist | Bayesian |
|---|---|---|
| **Definition** | Long-run frequency over infinite trials | Degree of belief, updated with evidence |
| **Parameters** | Fixed but unknown constants | Random variables with distributions |
| **Data** | Random sample from infinite population | Fixed once observed |
| **Core question** | P(Data \| H), "how likely is this data?" | P(H \| Data), "how likely is this hypothesis?" |

### Strengths and weaknesses

**Frequentist strengths:** No subjective prior required. Standardised and widely accepted in regulatory contexts. Computationally cheap for large datasets.

**Frequentist weaknesses:** p-values are chronically misinterpreted. Cannot directly state the probability that a hypothesis is true. Struggles with rare-event problems.

**Bayesian strengths:** Directly answers "how probable is my hypothesis?" Naturally incorporates prior knowledge. Produces a full posterior distribution for richer uncertainty quantification.

**Bayesian weaknesses:** Choice of prior is subjective. Posterior computation can be expensive for complex models. Less standardised across studies.

**The modern pragmatic view:** With large datasets and uninformative priors, the two frameworks converge. Most practitioners use whichever tool fits the problem.

## Experimenting with Frequentist Methods

### Frequentist module API

- `phi_approx(+Z, -CDF)`: standard normal CDF, using the Abramowitz and Stegun 26.2.17 approximation.
- `z_score(+Observed, +Expected, -Z)`: the difference, with `StdDev = 1.0`.
- `z_score(+Observed, +Expected, +StdDev, -Z)`: the standard z-score.
- `z_test_proportion(+Successes, +N, +HypP, -Result)`: one-sample z-test for a proportion. Returns `result(Z, PValue)`.
- `chi_squared_test(+Observed, +Expected, -Result)`: Pearson's chi-squared goodness-of-fit test, with `DF` one less than the number of categories. Returns `result(ChiSq, DF, PValue)`. A zero expected count throws `domain_error(non_zero_expected, E)`. (`chi_squared_test/4` is an older form, kept for compatibility.)
- `chi_squared_independence(+Table, -Result)`: Pearson's chi-squared test of independence for a table of counts, with `DF = (rows - 1) * (columns - 1)`. Returns `result(ChiSq, DF, PValue)`.
- `confidence_interval_proportion(+Successes, +N, +Confidence, -Result)`: Wilson score interval. Returns `result(Lower, Upper)`.

### Walking Through the Frequentist Code

The normal CDF approximation is the densest piece of math:

```prolog
phi_approx(Z, CDF) :-
    P  = 0.2316419,
    B1 = 0.319381530,
    B2 = -0.356563782,
    B3 = 1.781477937,
    B4 = -1.821255978,
    B5 = 1.330274429,
    AZ is abs(Z),
    TVal is 1.0 / (1.0 + P * AZ),
    PDF is exp(-0.5 * AZ * AZ) / sqrt(2.0 * pi),
    CDF0 is 1.0 - PDF * (B1*TVal
                         + B2*TVal^2
                         + B3*TVal^3
                         + B4*TVal^4
                         + B5*TVal^5),
    (   Z >= 0.0
    ->  CDF = CDF0
    ;   CDF is 1.0 - CDF0
    ).
```

The test of independence computes each expected count from the row and column totals: if the two variables are unrelated, the expected count in row `i`$ and column `j`$ is the row total times the column total divided by the grand total.

```prolog
%% chi_squared_independence(+Table, -result(ChiSq, DF, PValue))
%% Pearson's chi-squared test of independence for a contingency
%% table given as a list of rows of counts. H0: the row variable and
%% the column variable are independent. Expected counts come from the
%% row and column totals, and DF = (rows - 1) * (columns - 1).
chi_squared_independence(Table, result(ChiSq, DF, PVal)) :-
    maplist(sum_list, Table, RowTotals),
    transpose_rows(Table, Columns),
    maplist(sum_list, Columns, ColTotals),
    sum_list(RowTotals, Total),
    findall(T,
            ( nth1(I, Table, Row), nth1(J, Row, O),
              nth1(I, RowTotals, RT), nth1(J, ColTotals, CT),
              E is RT * CT / Total,
              chi_sq_term(O, E, T) ),
            Terms),
    sum_list(Terms, ChiSq),
    length(RowTotals, NR),
    length(ColTotals, NC),
    DF is (NR - 1) * (NC - 1),
    chi_squared_cdf(ChiSq, DF, CCDF),
    PVal is max(1.0 - CCDF, 0.0).

transpose_rows([[]|_], []) :- !.
transpose_rows(Rows, [Col|Cols]) :-
    maplist([[H|T], H, T]>>true, Rows, Col, Rests),
    transpose_rows(Rests, Cols).
```

For one degree of freedom, as in a 2×2 table, `chi_squared_cdf/3` uses the exact formula `P(\chi^2 \le x) = 2\Phi(\sqrt{x}) - 1`$. For three or more it uses the Wilson-Hilferty approximation, which is poor for one degree of freedom.

The Wilson score confidence interval is more accurate than the simple Wald interval for extreme proportions:

```prolog
confidence_interval_proportion(Successes, N, Confidence, result(Lower,
    Upper)) :-
    NF is float(N),
    P  is float(Successes) / NF,
    z_critical(Confidence, ZC),
    Z2 is ZC * ZC,
    Denom is 1.0 + Z2 / NF,
    Centre is (P + Z2 / (2.0 * NF)) / Denom,
    Margin is (ZC * sqrt(P * (1.0 - P) / NF + Z2 / (4.0 * NF * NF))) /
        Denom,
    Lower is max(0.0, Centre - Margin),
    Upper is min(1.0, Centre + Margin).
```

### Worked Example, Frequentist Medical Screening

The frequentist demo revisits the same scenario:

1. **Simulates a clinical trial**: 100,000 people screened.
2. **Chi-squared test of independence** on the 2×2 table of test result against disease: it rejects independence (p < 10⁻¹⁵), but this says nothing about the risk for one patient.
3. **Wilson CI for PPV**: the 95 % interval shows the PPV is only about 1.5 to 2.3 %.
4. **z-test**: the share of positive tests (5.1 %) differs hugely from the prevalence (0.1 %). The p-value is tiny, but the test answers a question nobody asked. Significance alone does not make a result useful.
5. **Side-by-side comparison**: the Bayesian posterior and the frequentist PPV agree.

{linenos=off}
~~~~~~~~
$ make freq
=== Running Frequentist medical screening example ===

================================================================
  FREQUENTIST ANALYSIS: Medical Screening Test
================================================================

--- 1. Simulated Clinical Trial (N = 100000) ---
  True  Positives (TP): 94
  False Positives (FP): 4982
  True  Negatives (TN): 94923
  False Negatives (FN): 1

--- 2. Chi-Squared Test of Independence ---
  chi-squared = 1739.02   df = 1   p-value < 1e-15

  The association exists but says nothing about
  how strong it is for one patient.

--- 3. Positive Predictive Value (PPV) ---
  PPV = 94 / 5076 = 0.0185  (1.85 %)
  95% Wilson CI for PPV: [0.0152, 0.0226]  (1.52% - 2.26%)

--- 4. Z-Test: Positive Rate vs. Prevalence ---
  Observed positive rate: 5.0760%
  Hypothesised rate (prevalence): 0.1000%
  z = 497.8490   p-value < 1e-15

--- 5. Bayesian vs. Frequentist Side-by-Side ---
  Bayesian posterior P(disease | positive) = 0.0194  (1.94%)
  Frequentist PPV from simulation          = 0.0185  (1.85%)

  Both frameworks agree: about 2% probability of illness.
================================================================
  Key lesson: statistical significance /= practical significance.
================================================================
~~~~~~~~

### Running the tests

{linenos=off}
~~~~~~~~
$ make test
% All 24 tests passed in 0.008 seconds (0.006 cpu)
~~~~~~~~

## Prolog-Specific Design Decisions

**Higher-order predicates.** `update/4` takes a likelihood predicate and calls it with `call/3`. The `:- meta_predicate update(+, +, 2, -)` declaration makes SWI-Prolog look up the predicate in the caller's module, which matters when the likelihood is defined outside the `bayes` module.

**Pairs.** Prolog's `-` operator gives a light pair syntax: `disease-0.001`. With `maplist` and partial application (`normalise_pair(Total)`), this gives a functional style with no extra libraries.

**Result terms.** The frequentist predicates return one `result(...)` term instead of several output arguments, which keeps related values together.

**Determinism.** The simulation loop in `frequentist_demo.pl` is a recursion with a cut in the base case (`simulate_loop(0, ...) :- !.`), so it leaves no choice points over 100,000 steps.

## Wrap Up

This chapter looked at probability from the Bayesian and frequentist points of view, using a medical screening example with a result that surprises almost everyone: an accurate test for a rare condition has a very low positive predictive value. The Bayesian method makes this plain by forcing you to use the base rate. The frequentist method confirms it with a confidence interval on the PPV, even while its chi-squared test reports a highly "significant" result.

The key takeaways are:

- **Always consider the base rate.** A 99 %-accurate test means little when the condition is rare.
- **Statistical significance is not practical significance.** A tiny p-value tells you an association exists; it does not tell you the association is large or useful.
- **Correlation does not equal causation, and even correlation does not equal reliable individual prediction.** The Pearson-r between test results and disease is real but insufficient for clinical decision-making.
- **Both frameworks have their place.** Bayesian methods suit problems where prior information matters. Frequentist methods dominate regulatory and large-sample settings. Most practitioners use both.

## Optional Practice Problems

1. **A Second Test**: A patient who tests positive takes a second, independent test with the same accuracy, and it is also positive. Call `update/4` twice in `medical_example.pl` to find the new posterior. How many positive tests does it take before the disease is more likely than not?
2. **Specificity**: Change `medical_example.pl` to take specificity instead of the false-positive rate. Plot (or print) the posterior after one positive test as specificity varies from 0.90 to 0.999.
3. **A Real Contingency Table**: Use `chi_squared_independence/2` on a 2×3 table of your own, and check the result against a statistics package or an online calculator.
