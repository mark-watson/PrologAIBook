# Probability

A SWI-Prolog library for exploring probability from both Bayesian and Frequentist perspectives. Companion code for the Probability chapter.

## Modules

- **bayes.pl** — Bayesian inference: model construction, Bayes' Theorem updates, posterior queries, MAP estimation.
- **correlation.pl** — Pearson-r, Spearman-ρ, and correlation matrices. Measures *association*, not causation.
- **frequentist.pl** — z-tests, chi-squared tests, Wilson confidence intervals. Classical hypothesis testing.
- **medical_example.pl** — Bayesian worked example: medical screening with 0.1% prevalence.
- **frequentist_demo.pl** — Frequentist analysis of the same scenario, with side-by-side Bayesian comparison.

## Running Examples

```shell
cd source-code/probability
make run    # Bayesian medical example
make freq   # Frequentist medical example
```

## Running Tests

```shell
make test
```

## Architecture

The library mirrors the four-module design of the Common Lisp version:

```
probability/
├── prolog/
│   ├── bayes.pl              # Bayesian toolkit
│   ├── correlation.pl        # Correlation toolkit
│   ├── frequentist.pl        # Frequentist toolkit
│   ├── medical_example.pl    # Bayesian worked example
│   └── frequentist_demo.pl   # Frequentist worked example
├── tests/
│   └── test_probability.pl   # Test suite
├── load.pl
├── Makefile
└── README.md
```
