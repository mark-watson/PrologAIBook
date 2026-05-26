# Janus ML

Call Python's scikit-learn from Prolog via the Janus bridge. Companion code for the Janus Python Bridge chapter.

## Running Examples

First, initialize the Python environment and install dependencies using `uv`. Note: you must specify the Python version that matches the one SWI-Prolog's Janus bridge was compiled against (e.g., Python 3.9):

```shell
uv sync --python 3.9
```

Then run the examples using `uv run` to ensure the virtual environment is used:

```shell
uv run swipl -s load.pl
```

Once the SWI-Prolog interactive shell opens, you can execute:

```prolog
?- py_classify([[1,0,0],[0,1,1],[1,1,0]], [[0,0,1]], Predictions).
Predictions = [1].

?- py_cluster([[1,2],[3,4],[1,3],[5,6]], 2, Labels).
Labels = [0, 1, 0, 1].
```

Requires SWI-Prolog compiled with Janus support and `uv` installed for Python dependency management.

### Data Formats

- **`py_classify(+TrainData, +TestData, -Predictions)`**:
  - `TrainData`: A list of lists where each inner list contains feature values followed by the class label as the last element (e.g., `[[Feature1, Feature2, Label], ...]`).
  - `TestData`: A list of lists of test samples. Since the Python bridge (`sklearn_bridge.py`) expects the same shape as `TrainData` and slices off the last element via `row[:-1]`, you **must** append a dummy/placeholder label as the last element of each test sample (e.g., `[[Feature1, Feature2, DummyLabel], ...]`).
- **`py_cluster(+Data, +NClusters, -Labels)`**:
  - `Data`: A list of lists of data points to cluster (e.g., `[[Feature1, Feature2], ...]`).
  - `NClusters`: The integer number of clusters to form.

## Running Tests

```shell
uv run swipl -g "['tests/test_janus_ml.pl'], run_tests, halt" -s load.pl
```

## Troubleshooting macOS Library Loading Issues

If you run `uv run swipl -s load.pl` on macOS and encounter a dynamic library loading error:
```
ERROR: open_shared_object/3: dlopen(.../janus.so, 0x0009): Library not loaded: @rpath/Python3.framework/Versions/3.9/Python3
```
This occurs because the Homebrew-compiled Janus package expects `Python3.framework` in the full Xcode bundle search path, but you may only have Xcode Command Line Tools installed.

To fix this permanently on your machine, add the Command Line Tools framework path to the shared library's `RPATH` list and re-sign the binary (otherwise macOS security will kill the process with exit code 137 / SIGKILL):

```shell
# 1. Make the library writable
chmod +w /opt/homebrew/Cellar/swi-prolog/10.0.2/lib/swipl/lib/arm64-darwin/janus.so

# 2. Add the Command Line Tools framework directory to its RPATHs
install_name_tool -add_rpath /Library/Developer/CommandLineTools/Library/Frameworks /opt/homebrew/Cellar/swi-prolog/10.0.2/lib/swipl/lib/arm64-darwin/janus.so

# 3. Restore read-only permission
chmod -w /opt/homebrew/Cellar/swi-prolog/10.0.2/lib/swipl/lib/arm64-darwin/janus.so

# 4. Re-sign the library to satisfy macOS security
codesign -f -s - /opt/homebrew/Cellar/swi-prolog/10.0.2/lib/swipl/lib/arm64-darwin/janus.so
```
*(Adjust the version path `10.0.2` if your installed version of SWI-Prolog is different).*

## Architecture

![Prolog-to-Python bridge for scikit-learn classification and clustering via Janus](FIG_janus_ml.jpg)

## Description

Demonstrates the Janus Python bridge for calling scikit-learn's DecisionTreeClassifier and KMeans clusterer directly from Prolog. The `py_sklearn.pl` module provides Prolog predicates that delegate to `python/sklearn_bridge.py` via `py_call/2`. This pattern lets you use Python's mature ML ecosystem while keeping Prolog as the orchestration and reasoning layer.
