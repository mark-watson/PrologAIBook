# Janus ML

Call Python's scikit-learn from Prolog via the Janus bridge. Companion code for the Janus Python Bridge chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- py_classify([[1,0,0],[0,1,1],[1,1,0]], [[0,0,1]], Predictions).
?- py_cluster([[1,2],[3,4],[1,3],[5,6]], 2, Labels).
```

Requires SWI-Prolog compiled with Janus support and Python with scikit-learn installed.

## Running Tests

```shell
swipl -g "['tests/test_janus_ml.pl'], run_tests, halt" -s load.pl
```

## Description

Demonstrates the Janus Python bridge for calling scikit-learn's DecisionTreeClassifier and KMeans clusterer directly from Prolog. The `py_sklearn.pl` module provides Prolog predicates that delegate to `python/sklearn_bridge.py` via `py_call/2`. This pattern lets you use Python's mature ML ecosystem while keeping Prolog as the orchestration and reasoning layer.
