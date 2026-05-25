# Probability

Probability theory provides the mathematical foundation for quantifying uncertainty. While classical frequentist approaches treat probability as the long-run frequency of repeatable events, Bayesian probability reframes it as a dynamic measure of belief. Through Bayes' Theorem, initial prior assumptions are systematically updated with incoming evidence to compute a posterior distribution, enabling rigorous inference even with sparse or evolving data.

Standard probabilistic models map correlations rather than causality. While observational probability can determine the likelihood of variables co-occurring, causal inference — often formalized through structural causal models — is required to understand directional influence. This distinction is critical: calculating the likelihood of observing a specific system state requires entirely different mathematical machinery than predicting the outcome of an intervention upon that system.

The source code for this chapter is in the directory **source-code/probability**.

## Words of Warning

Professor Carissa Véliz says in her book "Prophecy" that when you read a percentage you should first ask yourself if you are being told a fact or a prediction. If a percentage is a prediction, consciously tag it as "not a fact."

The danger of conflating the two lies in the illusion of precision that numbers naturally provide. A percentage representing a historical measurement is a grounded, verifiable reality. A predictive percentage is fundamentally an artifact of a specific model — heavily dependent on the chosen priors, the limits of the training data, and the structural assumptions baked into the algorithm. Consciously tagging a predictive percentage as "not a fact" forces a shift from passive acceptance to active critique: What variables is the model blind to? How fragile is this prediction to out-of-distribution events?

## Glossary of Terms

Before diving into the library and the worked examples, here is a reference for the statistical vocabulary used throughout this chapter.

**Prior (prior probability)** — Your initial belief about how likely a hypothesis is *before* you observe any new evidence. In the medical example below, the prior probability of disease is the prevalence rate (0.1 %). Priors can be informative (based on domain knowledge) or uninformative (deliberately vague).

**Posterior (posterior probability)** — Your updated belief about a hypothesis *after* incorporating observed evidence via Bayes' Theorem: P(Hypothesis | Data). In the medical example, the posterior probability of disease given a positive test is approximately 1.9 %.

**Likelihood** — The probability of observing the evidence *assuming a specific hypothesis is true*: P(Evidence | Hypothesis). In the medical example, the likelihood of a positive test result given disease is 0.99 (the sensitivity).

**Marginal likelihood (evidence)** — The total probability of the observed evidence across all hypotheses: Σ P(Evidence | H) · P(H). It acts as the normalising constant in Bayes' Theorem.

**Bayes' Theorem** — The mathematical rule connecting prior, likelihood, and posterior: P(H | E) = P(E | H) · P(H) / P(E).

**Maximum a posteriori (MAP)** — The hypothesis with the highest posterior probability — the Bayesian "best guess."

**Prevalence (base rate)** — The proportion of a population that has a particular condition. When the base rate is very low, even a highly accurate test produces many false positives relative to true positives.

**Sensitivity (true-positive rate)** — The probability that a test correctly identifies a positive case: P(Test+ | Condition+).

**Specificity (true-negative rate)** — The probability that a test correctly identifies a negative case: P(Test− | Condition−).

**False-positive rate** — The probability that a test incorrectly flags a healthy individual as positive: P(Test+ | Condition−).

**Positive predictive value (PPV)** — Among everyone who tested positive, the fraction who actually have the condition: TP / (TP + FP).

**Z-score (standard score)** — The number of standard deviations a data point lies from the mean: z = (x − μ) / σ.

**P-value** — The probability of observing data *at least as extreme* as what was measured, *assuming the null hypothesis is true*. Crucially, the p-value is **not** the probability that the hypothesis is true or false.

**Null hypothesis (H₀)** — The default assumption of "no effect" that a frequentist test tries to reject.

**Chi-squared test** — A test that compares observed counts against expected counts: Σ (O − E)² / E.

**Confidence interval (CI)** — A frequentist range estimate. A 95 % CI means: if you repeated the experiment many times, 95 % of the computed intervals would contain the true parameter.

**Wilson score interval** — A method for computing a confidence interval for a binomial proportion that is more accurate than the simple Wald interval, especially for small samples or proportions near 0 or 1.

**Pearson correlation coefficient (r)** — A measure of linear association between two variables, ranging from −1 to +1. It measures *association*, not causation.

**Spearman rank correlation (ρ)** — A non-parametric measure of monotonic association. More robust to outliers than Pearson-r.

## A SWI-Prolog Library to Explore Probability

### Design

The library provides four modules spanning both Bayesian and Frequentist reasoning:

1. **Bayesian Inference (`bayes.pl`)** — Model construction from hypothesis-probability pairs, Bayes' Theorem updates via `update/4`, posterior queries, and MAP estimation.

2. **Correlation helpers (`correlation.pl`)** — Pearson-r, Spearman rank correlation, and correlation matrices. These functions explicitly measure *association*, not causation.

3. **Frequentist Statistics (`frequentist.pl`)** — z-tests, chi-squared tests, and Wilson confidence intervals for classical hypothesis testing.

4. **Worked examples** — `medical_example.pl` demonstrates Bayesian reasoning on a screening test; `frequentist_demo.pl` revisits the same scenario from the frequentist standpoint.

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
Pearson r(test-result, disease) = 0.1349

=== Done. ===
~~~~~~~~

## Walking Through the Bayesian Code

### The Bayes Model

The core data structure is a normalised list of `Hypothesis-Probability` pairs. The constructor ensures priors sum to one:

{lang="prolog",linenos=off}
~~~~~~~~
make_bayes_model(PriorPairs, Model) :-
    maplist(pair_value, PriorPairs, Priors),
    sumlist(Priors, Total),
    (   Total =:= 0
    ->  throw(error(all_priors_zero,
        'All priors are zero — cannot normalise.'))
    ;   maplist(normalise_pair(Total), PriorPairs, Model)
    ).

pair_value(_-V, V).

normalise_pair(Total, H-P, H-NP) :-
    NP is P / Total.
~~~~~~~~

Prolog's `-` operator creates pairs naturally: `disease-0.001` is a term `-(disease, 0.001)`. The `maplist/normalise_pair` pattern applies partial application — `normalise_pair(Total)` is a goal with one argument already bound, and `maplist` supplies the remaining two.

### Updating with Evidence

The `update/4` predicate applies Bayes' Theorem. It uses Prolog's `meta_predicate` facility to accept a likelihood predicate as a higher-order argument:

{lang="prolog",linenos=off}
~~~~~~~~
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





                                  'Marginal likelihood is zero — evidence impossible under all hypotheses.'))
    ;   maplist(normalise_pair(Marginal), Unnormalised, Updated)
    ).

unnormalised_posterior(LikelihoodPred, H-Prior, H-UPost) :-
    call(LikelihoodPred, H, Lik),
    UPost is Lik * Prior.
~~~~~~~~

The `call/3` invocation is the key: `call(LikelihoodPred, H, Lik)` calls the likelihood predicate with the hypothesis and binds the likelihood value. This is Prolog's idiomatic higher-order pattern — the `meta_predicate` declaration ensures proper module resolution when the likelihood predicate is defined in a different module.

The `Marginal` variable is the denominator in Bayes' Theorem — dividing by it gives proper posterior probabilities that sum to one.

### The Medical Screening Example

The worked example makes Bayes' Theorem concrete. A rare disease affects 0.1 % of the population. A screening test has 99 % sensitivity and a 5 % false-positive rate. A patient tests positive — what is the probability they are actually sick?

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

The likelihood predicate is a clean two-clause definition — one clause per hypothesis. Prolog's pattern matching dispatches to the correct clause automatically. Passing `likelihood` (the predicate name) to `update/4` lets the Bayes engine call it via `call/3` for each hypothesis.

The answer is approximately **1.9 %**. Despite 99 % sensitivity, the disease is so rare that the vast majority of positive results come from the 5 % false-positive rate applied to the enormous healthy population.

### Correlation Analysis

The example also generates a synthetic population and computes the Pearson correlation between test results and disease status:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

The Pearson-r is positive but modest (~0.13). This illustrates a crucial point: a statistically real association does not translate into reliable individual prediction. You need Bayesian reasoning with the base rate for that.

## The Correlation Module

The Pearson correlation coefficient measures linear association. The implementation uses Prolog's `maplist` for the element-wise cross-deviation products:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

The Spearman rank correlation converts values to ranks (handling ties by averaging) and then computes Pearson-r on those ranks. This makes it robust to outliers and non-linear but monotonic relationships.

## Frequentists vs. Bayesians

The deepest fault-line in probability runs between two camps that disagree on what a probability *is*.

### What probability means

| | Frequentist | Bayesian |
|---|---|---|
| **Definition** | Long-run frequency over infinite trials | Degree of belief, updated with evidence |
| **Parameters** | Fixed but unknown constants | Random variables with distributions |
| **Data** | Random sample from infinite population | Fixed once observed |
| **Core question** | P(Data \| H) — "how likely is this data?" | P(H \| Data) — "how likely is this hypothesis?" |

### Strengths and weaknesses

**Frequentist strengths:** No subjective prior required. Standardised and widely accepted in regulatory contexts. Computationally cheap for large datasets.

**Frequentist weaknesses:** p-values are chronically misinterpreted. Cannot directly state the probability that a hypothesis is true. Struggles with rare-event problems.

**Bayesian strengths:** Directly answers "how probable is my hypothesis?" Naturally incorporates prior knowledge. Produces a full posterior distribution for richer uncertainty quantification.

**Bayesian weaknesses:** Choice of prior is subjective. Posterior computation can be expensive for complex models. Less standardised across studies.

**The modern pragmatic view:** With large datasets and uninformative priors, the two frameworks converge. Most practitioners use whichever tool fits the problem.

## Experimenting with Frequentist Methods

### Frequentist module API

- `phi_approx(+Z, -CDF)` — standard normal CDF using the Abramowitz & Stegun 26.2.17 rational approximation.
- `z_score(+Observed, +Expected, +StdDev, -Z)` — compute the standard z-score.
- `z_test_proportion(+Successes, +N, +HypP, -Result)` — one-sample z-test for a proportion. Returns `result(Z, PValue)`.
- `chi_squared_test(+Observed, +Expected, _, -Result)` — Pearson's chi-squared goodness-of-fit test. Returns `result(ChiSq, DF, PValue)`.
- `confidence_interval_proportion(+Successes, +N, +Confidence, -Result)` — Wilson score interval. Returns `result(Lower, Upper)`.

### Walking Through the Frequentist Code

The normal CDF approximation is the most mathematically dense piece:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

The Wilson score confidence interval is more accurate than the simple Wald interval for extreme proportions:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

### Worked Example — Frequentist Medical Screening

The frequentist demo revisits the same scenario:

1. **Simulates a clinical trial** — 100,000 individuals screened.
2. **Chi-squared test** — rejects independence (p < 10⁻¹⁵), but this tells you nothing about individual risk.
3. **Wilson CI for PPV** — the 95 % interval shows PPV is only about 1–3 %.
4. **Side-by-side comparison** — the Bayesian posterior and frequentist PPV agree.

{linenos=off}
~~~~~~~~
$ make freq
=== Running Frequentist medical screening example ===

================================================================
  FREQUENTIST ANALYSIS: Medical Screening Test
================================================================

--- 1. Simulated Clinical Trial (N = 100000) ---
  True  Positives (TP): 110
  False Positives (FP): 4938
  True  Negatives (TN): 94951
  False Negatives (FN): 1

--- 2. Chi-Squared Test of Independence ---
  chi-squared = 2050.74   df = 3   p-value < 1e-15

--- 3. Positive Predictive Value (PPV) ---
  PPV = 110 / 5048 = 0.0218  (2.18 %)
  95% Wilson CI for PPV: [0.0181, 0.0262]  (1.81% - 2.62%)

--- 5. Bayesian vs. Frequentist Side-by-Side ---
  Bayesian posterior P(disease | positive) = 0.0194  (1.94%)
  Frequentist PPV from simulation          = 0.0218  (2.18%)

  Both frameworks agree: about 2% probability of illness.
================================================================
  Key lesson: statistical significance /= practical significance.
================================================================
~~~~~~~~

### Running the tests

{linenos=off}
~~~~~~~~
$ make test
% All 15 tests passed in 0.011 seconds (0.007 cpu)
~~~~~~~~

## Prolog-Specific Design Decisions

**Higher-order predicates.** The `update/4` predicate accepts a likelihood predicate name and invokes it via `call/3`. The `:- meta_predicate update(+, +, 2, -)` declaration ensures SWI-Prolog resolves the predicate in the caller's module context — essential when the likelihood is defined in a different module than the Bayes engine.

**Pair representation.** Prolog's `-` operator provides a lightweight pair syntax: `disease-0.001`. Combined with `maplist` and partial application (`normalise_pair(Total)`), this gives a functional-programming flavour without external libraries.

**Result terms.** The frequentist predicates return structured `result(...)` terms rather than multiple output arguments. This bundles related values into a single unifiable term — cleaner than threading three separate variables through the caller.

**Determinism.** The simulation loop in `frequentist_demo.pl` uses explicit recursion with a cut in the base case (`simulate_loop(0, ...) :- !.`) to prevent choicepoint accumulation over 100,000 iterations.

## Wrap Up

This chapter explored probability from both the Bayesian and frequentist perspectives, using a medical screening scenario to illustrate a result that surprises almost everyone: a highly accurate test applied to a rare condition produces a dismally low positive predictive value. The Bayesian framework makes this transparent by forcing you to account for the base rate; the frequentist framework confirms it through confidence intervals on the PPV, even as its chi-squared test screams "significant!"

The key takeaways are:

- **Always consider the base rate.** A 99 %-accurate test means little when the condition is rare.
- **Statistical significance is not practical significance.** A tiny p-value tells you an association exists; it does not tell you the association is large or useful.
- **Correlation does not equal causation, and even correlation does not equal reliable individual prediction.** The Pearson-r between test results and disease is real but insufficient for clinical decision-making.
- **Both frameworks have their place.** Bayesian methods shine when prior information matters; frequentist methods dominate regulatory and large-sample settings. Pragmatic practitioners use both.
