# Anomaly Detection

Gaussian statistical anomaly detection applied to the Wisconsin Diagnostic Breast Cancer dataset. Companion code for the Anomaly Detection chapter.

Ported from the Java implementation in `../Java-AI-Book/source-code/anomaly_detection`.

## Running Examples

```shell
cd source-code/anomaly_detection
make run
```

Sample output (deterministic, since the pipeline seeds with `set_random(seed(42))`):

```
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
```

Deviations from the Java original:

- **Gaussian PDF divisor**: the Java `p()` method divides the summed PDF by the number of *columns* (10, including the class label) while only 9 input features are summed; the Prolog version divides by `num_input_features` (9).
- **Epsilon search**: the Java version tries a fixed grid of 20 values up to 0.951. On this data the best threshold lies above that, so `search_epsilon/2` instead tries the midpoint between each pair of neighbouring cross-validation densities. The grid search is still available as `search_epsilon/5`.
- **Full dataset**: the pipeline uses all 648 rows and runs in well under a second. `load_wisconsin_data/2` loads a stratified sample (class ratio preserved) for quick experiments.

## Running Tests

```shell
make test
```

## How It Works

The algorithm fits a Gaussian distribution to each input feature using only (mostly) normal training examples. At prediction time, features whose Gaussian PDF probability falls below a learned epsilon threshold are flagged as anomalies.

### Pipeline

1. **Load**: Read the Wisconsin cancer CSV (648 rows)
2. **Preprocess**: Scale features by 0.1, log-transform, min-max normalise per row, remap target to {0, 1}
3. **Split**: 60% training (mostly normal), ~28% cross-validation, ~12% test
4. **Fit statistics**: Compute per-feature mean (μ) and variance (σ²) from training data
5. **Search epsilon**: Try the midpoint between each pair of neighbouring cross-validation densities and keep the one with the fewest errors
6. **Evaluate**: Report precision, recall, and F1 on held-out test data

### Gaussian PDF

For each feature *i*, the probability density is:

```
p(x_i) = (1 / (√(2π) · σ_i)) · exp(-(x_i - μ_i)² / (2σ_i²))
```

A data point is flagged as an anomaly when the average per-feature PDF value falls below epsilon.

## Project Structure

- **`prolog/anomaly_detection.pl`**: Core module: data loading, preprocessing, Gaussian PDF, training, evaluation
- **`data/cleaned_wisconsin_cancer_data.csv`**: Wisconsin Diagnostic Breast Cancer dataset (648 rows, 10 columns)
- **`tests/test_anomaly_detection.pl`**: Unit tests for preprocessing, statistics, and the full pipeline

## Description

Implements anomaly detection using per-feature Gaussian probability density estimation. The model learns what "normal" looks like from training data, then flags data points that deviate significantly. This approach works well when anomalies are rare (few positive examples): the model only needs to characterise the normal distribution. The Wisconsin breast cancer dataset provides a practical demonstration: benign samples define the normal distribution, and malignant samples appear as statistical outliers.

## Copyright and License

Copyright 2022-2026 Mark Watson. All rights reserved. Apache 2 license.
