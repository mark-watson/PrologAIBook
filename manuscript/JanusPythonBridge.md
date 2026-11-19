# The Janus Python Bridge

SWI-Prolog's Janus library connects Prolog and Python in both directions. Prolog programs can use Python's data science libraries (NumPy, scikit-learn, spaCy, transformers), and Python programs can use Prolog rules.

{width: "80%"}
![Architecture diagram for the Janus ML Bridge example](FIG_janus_ml.jpg)

## Setting Up Janus

Janus works in both directions, and each direction is set up differently:

- **Prolog calling Python.** SWI-Prolog 9 and later include `library(janus)`, which embeds a Python interpreter in the Prolog process. It embeds the Python that SWI-Prolog was *built with*. You cannot choose a different Python at run time.
- **Python calling Prolog.** The Python package `janus-swi` embeds SWI-Prolog in a Python process. Install it with `uv add janus-swi` or `pip install janus-swi`.

### Python Packages for Prolog Programs

When Prolog calls Python, where do packages such as scikit-learn come from? Janus reads the `VIRTUAL_ENV` environment variable and uses the packages of that virtual environment. The environment must use the same Python version that Janus embeds, or compiled packages such as NumPy will not load.

The book's Janus projects use `uv` for this. Their Makefiles create the environment with the matching Python and start `swipl` with `VIRTUAL_ENV` set. Here is **janus_ml_python_interop/Makefile**:

```makefile
# Makefile for janus_ml - scikit-learn from Prolog via Janus
# Usage: make [all|run|test|venv]
#
# Janus embeds the Python that SWI-Prolog was built with, so the
# virtual environment must use that same Python. For the Homebrew
# build on macOS it is the Command Line Tools Python 3.9
# (/usr/bin/python3), and janus.so finds its framework only through
# DYLD_FRAMEWORK_PATH. On Linux the system python3 is usually right.
# Janus uses the packages of the environment named by VIRTUAL_ENV.

SWIPL  = swipl
PYTHON ?= /usr/bin/python3
VENV   = $(CURDIR)/.venv

ifeq ($(shell uname),Darwin)
JANUS_ENV = DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/Library/Frameworks
endif

RUN_SWIPL = VIRTUAL_ENV=$(VENV) $(JANUS_ENV) $(SWIPL)

.PHONY: all run test tests venv

all: run test

venv: $(VENV)/pyvenv.cfg

$(VENV)/pyvenv.cfg: pyproject.toml
	uv sync --python $(PYTHON)
	@touch $@

run: venv
	@echo "=== Running janus_ml - scikit-learn from Prolog via Janus examples ==="
	@$(RUN_SWIPL) -g "py_classify([[1,0,0],[0,1,1],[1,1,0]], [[0,0],[1,0]], P), format('Decision tree predictions: ~w~n', [P]), py_cluster([[0.0,0.0],[0.1,0.0],[9.0,9.0],[9.1,9.0]], 2, L), format('KMeans cluster labels: ~w~n', [L]), halt" -s load.pl

test: venv
	@echo "=== Running janus_ml - scikit-learn from Prolog via Janus tests ==="
	$(RUN_SWIPL) -g "['tests/test_janus_ml.pl'], run_tests, halt" -s load.pl

tests: test
```

`make venv` runs `uv sync`, which reads the dependencies from **pyproject.toml** and the exact versions from **uv.lock**. Note that the Makefile does not use `uv run swipl`: `uv run` drops `DYLD_*` environment variables, which the macOS fix below needs.

### The macOS Python Framework

The Homebrew build of SWI-Prolog embeds Apple's Python 3.9 from the Command Line Tools, but its `janus.so` looks for `Python3.framework` only inside the full Xcode app. If you have only the Command Line Tools, loading Janus fails with:

```
ERROR: open_shared_object/3: dlopen(.../janus.so, 0x0009): Library not loaded: @rpath/Python3.framework/Versions/3.9/Python3
```

The simplest fix changes nothing on disk. Tell the dynamic loader where the framework is:

```shell
export DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/Library/Frameworks
```

The Makefiles set this for you on macOS. For a permanent fix, add the directory to the library's search path and re-sign it. This edits a file inside your Homebrew installation, and upgrading SWI-Prolog undoes it:

```shell
JANUS=/opt/homebrew/Cellar/swi-prolog/10.0.2/lib/swipl/lib/arm64-darwin/janus.so
chmod +w $JANUS
install_name_tool -add_rpath /Library/Developer/CommandLineTools/Library/Frameworks $JANUS
chmod -w $JANUS
codesign -f -s - $JANUS     # macOS kills unsigned modified libraries
```

Adjust `10.0.2` to your installed version. On Linux, the system `python3` is usually the right one, so run `make venv PYTHON=python3` and no framework fix is needed.

### Telling Python Where Your Modules Are

Before Prolog can call your own Python modules, Python must find them. `py_add_lib_dir/1` adds a directory to Python's `sys.path`. A relative path such as `python` is resolved against the current directory, so it breaks when you run the program from elsewhere. The book's modules use the directory of the Prolog file instead:

```prolog
:- prolog_load_context(directory, PrologDir),
   directory_file_path(PrologDir, '../python', PyDir),
   py_add_lib_dir(PyDir).
```

`prolog_load_context(directory, Dir)` gives the directory of the file being loaded. Avoid `:- initialization(Goal, main)` in a library module: the `main` option makes Prolog halt when `Goal` finishes.

### Testing the Connection

From the `janus_ml_python_interop` directory, after `make venv`:

```shell
$ VIRTUAL_ENV=$PWD/.venv \
  DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/Library/Frameworks \
  swipl
?- use_module(library(janus)).
true.

?- py_call(sys:prefix, P).
P = '/.../janus_ml_python_interop/.venv'.
```

`sys.prefix` names the virtual environment, which confirms that Janus is using it. In the other direction, a Python program can run a Prolog query:

```python
import janus_swi as janus
print(janus.query_once("X is 2 + 3"))
# {'truth': True, 'X': 5}
```

## Calling Python from Prolog

The main predicates are `py_call/2` and `py_call/3`:

- **`py_call(+Call, -Return)`** calls a Python function or reads an attribute. `Call` has the form `Module:Function(Args...)` or `Module:Attribute`. Janus converts the arguments to Python values and the result back to a Prolog term.
- **`py_call(+Call, -Return, +Options)`** takes options, including:
  - `py_object(true)`: return a reference to the Python object instead of converting it. Use this to keep a large object, such as a trained model, in Python between calls.
  - `py_string_as(Type)`: return Python strings as `atom` (the default) or `string`.

A Python exception becomes a Prolog exception, `python_error(Class, Value)`, which you can catch with `catch/3`.

### Data Conversion Reference

| Prolog | Python | Back to Prolog |
| :--- | :--- | :--- |
| Atom `apple` | `'apple'` | atom `apple` |
| String `"apple"` | `'apple'` | atom `apple` (default) |
| Integer, float | `int`, `float` | integer, float |
| List `[1, 2]` | `[1, 2]` | `[1, 2]` |
| Dict `_{a:1}` | `{'a': 1}` | `py{a:1}` |
| `1-2` | tuple `(1, 2)` | `1-2` |
| `@true`, `@false`, `@none` | `True`, `False`, `None` | `@true`, `@false`, `@none` |
| Python object reference | the object | the reference |

Note the last column: a Python string comes back as a Prolog *atom* unless you ask for strings, and a dict comes back with the tag `py`.

The **janus_ml_python_interop** project calls scikit-learn from Prolog. Here is the file **janus_ml_python_interop/prolog/py_sklearn.pl**:

```prolog
%% py_sklearn.pl - Call scikit-learn from Prolog via Janus
:- module(py_sklearn, [
    py_classify/3,
    py_cluster/3
]).

:- use_module(library(janus)).

% Add the companion python/ directory to Python's module search path.
% prolog_load_context/2 gives this file's directory while it loads, so
% the module works from any current working directory.
:- prolog_load_context(directory, PrologDir),
   directory_file_path(PrologDir, '../python', PyDir),
   py_add_lib_dir(PyDir).

%% py_classify(+TrainData, +TestData, -Predictions)
%% Uses scikit-learn's DecisionTreeClassifier via Janus.
%% TrainData rows are labelled:  [[f1, ..., fN, label], ...].
%% TestData rows may be given WITHOUT a trailing dummy label; if a test
%% row is one element shorter than a training row a dummy 0 label is
%% appended internally before calling Python, which keeps backwards
%% compatibility with the old calling convention.
py_classify(TrainData, TestData, Predictions) :-
    (   TrainData = [TrainRow|_]
    ->  true
    ;   domain_error(non_empty_list, TrainData)
    ),
    length(TrainRow, TrainWidth),
    maplist(normalise_test_row(TrainWidth), TestData, Normalised),
    py_call(sklearn_bridge:classify(TrainData, Normalised),
        Predictions).

% Python receives unlabelled feature vectors: strip the dummy label
% when the caller appended one, or append a 0 dummy for callers that
% passed a bare feature vector (the new preferred calling style).
normalise_test_row(TrainWidth, Row, Features) :-
    length(Row, W),
    FeaturesWidth is TrainWidth - 1,
    (   W =:= FeaturesWidth
    ->  Features = Row
    ;   W =:= TrainWidth
    ->  length(Features, FeaturesWidth),
        append(Features, [_Dummy], Row)
    ;   domain_error(train_width_or_train_width_minus_1, Row)
    ).

%% py_cluster(+Data, +NClusters, -Labels)
%% Uses scikit-learn's KMeans via Janus
py_cluster(Data, NClusters, Labels) :-
    py_call(sklearn_bridge:cluster(Data, NClusters), Labels).
```

`py_classify/3` accepts test rows with or without a dummy label, and an empty training set raises a `domain_error` in Prolog before any Python runs. Here is the Python side, **janus_ml_python_interop/python/sklearn_bridge.py**:

```python
"""sklearn_bridge.py - Python-side bridge for Janus ML integration"""

from sklearn.tree import DecisionTreeClassifier
from sklearn.cluster import KMeans
import numpy as np


def _check_rows(rows, name):
    if rows is None or len(rows) == 0:
        raise ValueError(f"{name} must be a non-empty list of rows")
    width = len(rows[0])
    if width == 0:
        raise ValueError(f"{name} rows must be non-empty lists")
    for row in rows:
        if len(row) != width:
            raise ValueError(
                f"{name} rows must all have the same length "
                f"(expected {width}, got {len(row)})")
    return width


def classify(train_data, test_data):
    """Train a DecisionTreeClassifier and predict on test data.

    train_data rows are labelled: [f1, ..., fN, label].
    test_data rows are unlabelled feature vectors: [f1, ..., fN].
    """
    train_width = _check_rows(train_data, "train_data")
    _check_rows(test_data, "test_data")
    if train_width < 2:
        raise ValueError(
            "train_data rows need at least one feature and a label")
    X_train = [row[:-1] for row in train_data]
    y_train = [row[-1] for row in train_data]
    X_test = [list(row) for row in test_data]
    for row in X_test:
        if len(row) != train_width - 1:
            raise ValueError(
                f"test_data rows must have {train_width - 1} features, "
                f"got {len(row)}")

    clf = DecisionTreeClassifier(random_state=42)
    clf.fit(X_train, y_train)
    predictions = clf.predict(X_test)
    return predictions.tolist()


def cluster(data, n_clusters):
    """Run KMeans clustering and return cluster labels."""
    _check_rows(data, "data")
    if not isinstance(n_clusters, int) or n_clusters < 1:
        raise ValueError("n_clusters must be a positive integer")
    if n_clusters > len(data):
        raise ValueError(
            f"n_clusters={n_clusters} exceeds number of samples "
            f"{len(data)}")
    X = np.array(data)
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    kmeans.fit(X)
    return kmeans.labels_.tolist()
```

## Hybrid AI Pipelines

The **hybrid pipeline** pattern from the LLM Integration chapter fits Janus well: Python libraries handle statistical tasks (tokenizing, named entity recognition, embeddings), and Prolog handles rules, constraints, and reasoning:
1. **Python** turns unstructured data, such as text, into structured records.
2. **Prolog** asserts the records as facts and applies its rules.
3. **Explanations** come from the Prolog side, where proof trees can show why each conclusion holds.

The **hybrid_pipeline** project combines spaCy for named entity recognition with Prolog rules. Here is **hybrid_pipeline/prolog/pipeline.pl**:

```prolog
%% pipeline.pl - Hybrid AI pipeline: Python preprocessing + Prolog
%% reasoning
:- module(pipeline, [
    run_pipeline/2,
    ner_backend/1
]).

:- use_module(library(janus)).

:- dynamic extracted/2.

% Add the companion python/ directory to Python's module search path.
% prolog_load_context/2 gives this file's directory while it loads, so
% the module works from any current working directory.
:- prolog_load_context(directory, PrologDir),
   directory_file_path(PrologDir, '../python', PyDir),
   py_add_lib_dir(PyDir).

%% ner_backend(-Name)
%% Name is spacy when spaCy and its model loaded, else rules.
ner_backend(Name) :-
    py_call(nlp_bridge:backend(), Name).

%% run_pipeline(+InputText, -Result)
%% 1. Use Python/spaCy for NER extraction
%% 2. Assert extracted entities as Prolog facts
%% 3. Apply Prolog reasoning rules
%% 4. Return structured conclusions
run_pipeline(InputText, Result) :-
    setup_call_cleanup(
        true,
        (   %% Step 1: Python NER
            py_call(nlp_bridge:extract_entities(InputText), Entities),
            %% Step 2: Assert as Prolog facts
            maplist(assert_entity, Entities),
            %% Step 3: Prolog reasoning
            findall(conclusion(E, Type), entity_conclusion(E, Type),
                Conclusions),
            Result = pipeline_result(Entities, Conclusions)
        ),
        %% Cleanup: always retract, even on failure or exception
        retractall(extracted(_,_))).

%% extract_entities/1 returns a list of dicts:  _{text: T, label: L}
assert_entity(Entity) :-
    Text = Entity.text,
    Type = Entity.label,
    assertz(extracted(Text, Type)).

%% Only PERSON and GPE labels are mapped to conclusions; every other
%% spaCy entity label is deliberately dropped by these two clauses.
entity_conclusion(E, important_person) :-
    extracted(E, 'PERSON').
entity_conclusion(E, location) :-
    extracted(E, 'GPE').
```

Here is the Python side, **hybrid_pipeline/python/nlp_bridge.py**. It returns plain dicts, which Janus turns into `py{...}` dicts that `assert_entity/1` reads with dot notation. If spaCy or its English model is missing, it falls back to a few known names, and `backend()` reports which method is in use:

```python
"""nlp_bridge.py - Python-side bridge for Janus Hybrid NLP Pipeline"""

import warnings

# The macOS system Python links an old LibreSSL; urllib3 (pulled in by
# spaCy) warns about it on import. The warning does not affect NER.
warnings.filterwarnings("ignore", message=".*OpenSSL.*")

# Load spaCy and its small English model; fall back to simple rules if
# either is missing.
try:
    import spacy
    nlp = spacy.load("en_core_web_sm")
except Exception:
    spacy = None
    nlp = None


def backend():
    """Name of the NER method in use: 'spacy' or 'rules'."""
    return "spacy" if nlp is not None else "rules"


def _dict_entity(text, label):
    """One entity as a plain dict; Janus converts dicts to Prolog dicts."""
    return {'text': text, 'label': label}


def mock_entities(text):
    """Rule-based fallback used when spaCy (or its model) is unavailable.

    Public so the test suite can exercise the fallback explicitly.
    """
    entities = []
    for word in text.split():
        clean = word.strip(",.")
        if clean in ["John", "Smith"]:
            entities.append(_dict_entity(clean, "PERSON"))
        elif clean in ["London", "Paris"]:
            entities.append(_dict_entity(clean, "GPE"))
    return entities


def extract_entities(text):
    """Extract Named Entities from text. Uses spaCy or a mock rule-based
    fallback. Returns a list of {'text': str, 'label': str} dicts so both
    paths hand Prolog the exact same shape."""
    if nlp is None:
        return mock_entities(text)
    doc = nlp(text)
    return [_dict_entity(ent.text, ent.label_) for ent in doc.ents]
```

## Calling Prolog from Python

In the other direction, a Python program runs Prolog queries. The `janus_swi` package embeds SWI-Prolog in the Python process. This is a good way to add Prolog **policy rules** or **guardrails** to a Python web service or LLM pipeline.

### The Janus Python API

The main functions are:

- **`janus.consult(path)`** loads a Prolog file.
- **`janus.query_once(query, inputs)`** runs a query once. `inputs` is a dict that binds Prolog variables before the query runs. It returns a dict with a `'truth'` key and one key per output variable, such as `{'truth': True, 'L': 5}`. A failed query returns `{'truth': False}`, not `False`, so test `result['truth']`.
- **`janus.query(query, inputs)`** returns an iterator with one dict per solution: `list(janus.query('member(X, [a,b])'))` gives `[{'truth': True, 'X': 'a'}, {'truth': True, 'X': 'b'}]`.
- **`janus.apply(module, predicate, *args)`** calls a predicate directly.

Here Python loads the guardrail rules from the LLM Logic Guardrails chapter and checks a portfolio:

```python
import janus_swi as janus

# Load the Prolog rules
janus.consult("guardrails.pl")

# Execute a query with input bindings
json_input = '{"client_age": 70, "risk_tolerance": "low", "allocations": {"stocks": 40}}'
result = janus.query_once("validate_portfolio_json(Json, Errors)", {"Json": json_input})

if result["truth"]:
    print("Violations:", result["Errors"])
else:
    print("Query failed.")
```

## Practical Applications

Three ways to combine Python's machine learning libraries with Prolog's reasoning:

### 1. LLM Guardrails & Compliance
LLMs handle language well but cannot guarantee that their output obeys exact rules (regulations, arithmetic, safety limits). A Python application can pass an LLM's JSON output to Prolog through `janus_swi`, check it against rules before a user sees it, and send any violations back to the LLM for a corrected answer. The LLM Logic Guardrails chapter builds this.

### 2. Constraint-Guided Optimization
Python code can gather data (scraping, web APIs, image or speech processing) and turn it into facts. Prolog's constraint libraries, such as `clpfd`, can then solve scheduling, allocation, or routing problems over those facts and return the answer to Python.

### 3. Explainable Machine Learning (XAI)
Deep learning models are hard to audit. Python can run a neural classifier or object detector and pass its labels and confidence scores to Prolog, where rules combine them into a decision with an explanation a person can read.

## Optional Practice Problems

1. **Train Once, Predict Many**: Change `py_sklearn.pl` so `py_train/2` returns the fitted model as a Python object reference (`py_object(true)`) and `py_predict/3` uses it, instead of training on every call.
2. **All Solutions in Python**: Write a Python script that loads `tutorial_basics/prolog/family.pl` with `janus.consult` and prints every grandparent pair using `janus.query`.
3. **More Entity Types**: Add Prolog rules to `pipeline.pl` for spaCy's `ORG` and `DATE` labels, and test them on a sentence of your own.
