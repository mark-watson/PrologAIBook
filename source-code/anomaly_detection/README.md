# Anomaly Detection

Gaussian statistical anomaly detection applied to the Wisconsin Diagnostic Breast Cancer dataset. Companion code for the Anomaly Detection chapter.

Ported from the Java implementation in `../Java-AI-Book/source-code/anomaly_detection`.

## Running Examples

```shell
cd source-code/anomaly_detection
make run
```

Sample output:

```
Split: 86 train, 45 cv, 22 test

**** Best epsilon value = 0.801000

 -- number of test examples = 22
 -- true positives  = 6
 -- false positives = 0
 -- false negatives = 3
 -- true negatives  = 13
 -- precision = 1.000000
 -- recall    = 0.666667
 -- F1        = 0.800000
```

## Running Tests

```shell
make test
```

## How It Works

The algorithm fits a Gaussian distribution to each input feature using only (mostly) normal training examples. At prediction time, features whose Gaussian PDF probability falls below a learned epsilon threshold are flagged as anomalies.

### Pipeline

1. **Load & subsample** — Read the Wisconsin cancer CSV (~648 rows), randomly subsample to ~200 for Prolog performance
2. **Preprocess** — Scale features by 0.1, log-transform, min-max normalise per row, remap target to {0, 1}
3. **Split** — 60% training (mostly normal), ~28% cross-validation, ~12% test
4. **Fit statistics** — Compute per-feature mean (μ) and variance (σ²) from training data
5. **Search epsilon** — Grid search over 20 epsilon values, minimising cross-validation error count
6. **Evaluate** — Report precision, recall, and F1 on held-out test data

### Gaussian PDF

For each feature *i*, the probability density is:

```
p(x_i) = (1 / (√(2π) · σ_i)) · exp(-(x_i - μ_i)² / (2σ_i²))
```

A data point is flagged as an anomaly when the average per-feature PDF value falls below epsilon.

## Project Structure

- **`prolog/anomaly_detection.pl`** — Core module: data loading, preprocessing, Gaussian PDF, training, evaluation
- **`data/cleaned_wisconsin_cancer_data.csv`** — Wisconsin Diagnostic Breast Cancer dataset (648 rows, 10 columns)
- **`tests/test_anomaly_detection.pl`** — Unit tests for preprocessing, statistics, and the full pipeline

## Description

Implements anomaly detection using per-feature Gaussian probability density estimation. The model learns what "normal" looks like from training data, then flags data points that deviate significantly. This approach works well when anomalies are rare (few positive examples) — the model only needs to characterise the normal distribution. The Wisconsin breast cancer dataset provides a practical demonstration: benign samples define the normal distribution, and malignant samples appear as statistical outliers.

## Copyright and License

Copyright 2022-2026 Mark Watson. All rights reserved. Apache 2 license.
