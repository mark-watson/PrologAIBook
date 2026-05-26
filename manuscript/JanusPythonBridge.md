# The Janus Python Bridge

SWI-Prolog's Janus library provides seamless bidirectional interoperability between Prolog and Python. This opens up the entire Python data science ecosystem — NumPy, scikit-learn, spaCy, transformers — to Prolog programs.

{width: "80%"}
![Architecture diagram for the Janus ML Bridge example](FIG_janus_ml.jpg)

## Setting Up Janus

For bidirectional integration, Janus requires both Python and SWI-Prolog to be configured so they can find each other.

### Installation

If you are using a modern SWI-Prolog distribution (version 9.x or later), the Janus Prolog library is typically pre-packaged and included by default. On the Python side, you need to install the companion package `janus-swi`. Using `uv` is the recommended way to manage dependencies in this book:

```shell
uv add janus-swi
```

Alternatively, you can install it using standard `pip`:

```shell
pip install janus-swi
```

### Configuring Python Paths from Prolog

Before Prolog can load and run your custom Python modules, it needs to know where those files reside. SWI-Prolog's Janus library provides the `py_add_lib_dir/1` predicate to add directories to Python's module search path (`sys.path`).

For example, if your Python scripts are in a subdirectory named `python`, you initialize the path using:

```prolog
:- initialization(py_add_lib_dir(python)).
```

You can also set the standard `PYTHONPATH` environment variable in your terminal before starting SWI-Prolog:

```shell
export PYTHONPATH="./python:$PYTHONPATH"
```

### Testing the Connection

Once installed, you can quickly verify that Prolog can call Python. Start SWI-Prolog and query the Python version:

```prolog
?- use_module(library(janus)).
true.

?- py_call(sys:version, Version).
Version = '3.9.6 (default, ...)'
```

Similarly, you can verify that Python can invoke Prolog. Start a Python shell and run a simple Prolog query:

```python
import janus_swi as janus
result = janus.query_once("X is 2 + 3")
print(result)
# Output: {'X': 5}
```

### Troubleshooting macOS Library Loading Issues

On macOS, running Janus may occasionally fail with a dynamic library loading error like:

```
ERROR: open_shared_object/3: dlopen(.../janus.so, 0x0009): Library not loaded: @rpath/Python3.framework/Versions/3.9/Python3
```

This happens if the SWI-Prolog package expects `Python3.framework` in the full Xcode bundle search path, but you only have Xcode Command Line Tools installed. You can fix this by updating the shared library's `RPATH` list and re-signing the binary:

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
*(Adjust the version path `10.0.2` if your installed version of SWI-Prolog differs).*

## Calling Python from Prolog

Janus provides two primary predicates to call Python from Prolog: `py_call/2` and `py_call/3`.

- **`py_call(+Call, -Return)`**: Invokes a Python function or accesses a module attribute. The format for `Call` is `Module:Function(Args...)` or `Module:Attribute`. Janus automatically marshals Prolog terms to Python types and translates the return value back to a Prolog term.
- **`py_call(+Call, -Return, +Options)`**: Provides additional options to control call evaluation and return type conversion. Key options include:
  - `py_object(true)`: Returns a reference to the Python object (as a Prolog blob handle) rather than converting the object into a native Prolog term. This is useful for passing complex objects (like machine learning models or large datasets) back to Python in subsequent calls without translation overhead.
  - `py_type(Type)`: Guides the translation behavior (e.g. converting a Python sequence to a list or tuple).

### Data Conversion Reference

| Prolog Term | Python Object | Notes |
| :--- | :--- | :--- |
| Atom (e.g., `apple`) | String (`'apple'`) | |
| String (e.g., `"apple"`) | String (`'apple'`) | |
| Integer | Integer | |
| Float | Float | |
| List (e.g., `[1, 2]`) | List (`[1, 2]`) | |
| Dict (e.g., `json{a:1}`) | Dict (`{'a': 1}`) | Maps SWI-Prolog dicts to Python dicts |
| Blob (reference) | Python Object | Opaque references passed back to Python |

The **janus_ml_python_interop** project demonstrates calling scikit-learn from Prolog. Here is the file **janus_ml_python_interop/prolog/py_sklearn.pl**:

```prolog
%% py_sklearn.pl - Call scikit-learn from Prolog via Janus
:- module(py_sklearn, [
    py_classify/3,
    py_cluster/3
]).

:- use_module(library(janus)).

:- initialization(py_add_lib_dir(python)).

%% py_classify(+TrainData, +TestData, -Predictions)
%% Uses scikit-learn's DecisionTreeClassifier via Janus
py_classify(TrainData, TestData, Predictions) :-
    py_call(sklearn_bridge:classify(TrainData, TestData), Predictions).

%% py_cluster(+Data, +NClusters, -Labels)
%% Uses scikit-learn's KMeans via Janus
py_cluster(Data, NClusters, Labels) :-
    py_call(sklearn_bridge:cluster(Data, NClusters), Labels).
```

The companion Python module **janus_ml_python_interop/python/sklearn_bridge.py** wraps the scikit-learn models:

```python
"""sklearn_bridge.py - Python-side bridge for Janus ML integration"""

from sklearn.tree import DecisionTreeClassifier
from sklearn.cluster import KMeans
import numpy as np

def classify(train_data, test_data):
    """Train a DecisionTreeClassifier and predict on test data."""
    X_train = [row[:-1] for row in train_data]
    y_train = [row[-1] for row in train_data]
    X_test = [row[:-1] for row in test_data]

    clf = DecisionTreeClassifier()
    clf.fit(X_train, y_train)
    predictions = clf.predict(X_test)
    return predictions.tolist()

def cluster(data, n_clusters):
    """Run KMeans clustering and return cluster labels."""
    X = np.array(data)
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    kmeans.fit(X)
    return kmeans.labels_.tolist()
```

## Hybrid AI Pipelines

A powerful Neuro-Symbolic AI pattern is the **hybrid pipeline**: using Python's mature libraries for statistical and perceptual tasks (like tokenization, Named Entity Recognition, or embedding retrieval) and Prolog for symbolic logic, constraint checking, and reasoning.

This architecture has several distinct advantages:
1. **Separation of Concerns**: Python handles unstructured, high-dimensional data (e.g. natural language) and converts it into structured records.
2. **Dynamic Assertion**: Prolog receives the structured records, asserts them dynamically, and fires logical inference rules.
3. **Traceability**: Prolog rules are declarative and produce explainable proof trees, overcoming the "black box" limitation of machine learning models.

The **hybrid_pipeline** project combines Python NLP (using `spaCy` for Named Entity Recognition) with Prolog reasoning rules. Here is the Prolog orchestration file **hybrid_pipeline/prolog/pipeline.pl**:

```prolog
%% pipeline.pl - Hybrid AI pipeline: Python preprocessing + Prolog
%% reasoning
:- module(pipeline, [
    run_pipeline/2
]).

:- use_module(library(janus)).

:- initialization(py_add_lib_dir(python)).

%% run_pipeline(+InputText, -Result)
%% 1. Use Python/spaCy for NER extraction
%% 2. Assert extracted entities as Prolog facts
%% 3. Apply Prolog reasoning rules
%% 4. Return structured conclusions
run_pipeline(InputText, Result) :-
    %% Step 1: Python NER
    py_call(nlp_bridge:extract_entities(InputText), Entities),
    %% Step 2: Assert as Prolog facts
    maplist(assert_entity, Entities),
    %% Step 3: Prolog reasoning
    findall(conclusion(E, Type), entity_conclusion(E, Type),
        Conclusions),
    Result = pipeline_result(Entities, Conclusions),
    %% Cleanup
    retractall(extracted(_,_)).

:- dynamic extracted/2.

assert_entity(Entity) :-
    py_call(Entity:label_, Type),
    py_call(Entity:text, Text),
    assert(extracted(Text, Type)).

entity_conclusion(E, important_person) :-
    extracted(E, 'PERSON').
entity_conclusion(E, location) :-
    extracted(E, 'GPE').
```

Here is the Python companion script **hybrid_pipeline/python/nlp_bridge.py** which defines the Named Entity Recognition bridge. It uses `spaCy` to extract entities but includes a lightweight regex/rule-based fallback so the example can run even if the spaCy pipeline isn't fully set up:

```python
"""nlp_bridge.py - Python-side bridge for Janus Hybrid NLP Pipeline"""

# Load spaCy, fallback gracefully if not installed
try:
    import spacy
    nlp = spacy.load("en_core_web_sm")
except (ImportError, Exception):
    spacy = None
    nlp = None

class MockEntity:
    def __init__(self, text, label):
        self.text = text
        self.label_ = label

def extract_entities(text):
    """Extract Named Entities from text. Uses spaCy or a mock rule-based fallback."""
    if nlp is None:
        entities = []
        for word in text.split():
            clean = word.strip(",.")
            if clean in ["John", "Smith"]:
                entities.append(MockEntity(clean, "PERSON"))
            elif clean in ["London", "Paris"]:
                entities.append(MockEntity(clean, "GPE"))
        return entities
    
    doc = nlp(text)
    return [MockEntity(ent.text, ent.label_) for ent in doc.ents]
```

## Calling Prolog from Python

We can also run the bridge in the opposite direction: driving our application from a Python script and querying a Prolog logic engine to evaluate rules. Janus provides the `janus_swi` module for Python, which embeds SWI-Prolog directly inside the Python process.

This is highly useful for adding symbolic **policy engines**, **safety guardrails**, or **decision trees** on top of Python web services or LLM pipelines.

### The Janus Python API

The `janus_swi` module provides several key methods to interact with Prolog:

- **`janus.consult(path_to_prolog_file)`**: Loads a Prolog source file into the embedded engine.
- **`janus.query_once(query_string, inputs)`**: Executes a Prolog query exactly once. The `inputs` parameter is a dictionary mapping Python variables to Prolog terms. It returns a dictionary of variable bindings if the query succeeds, or `False` if it fails.
- **`janus.query(query_string, inputs)`**: Runs a Prolog query and returns a Python generator. Iterating over the generator yields bindings for all matching solutions, which is ideal for multi-valued backtracking queries.
- **`janus.apply(module_or_predicate, *args)`**: Invokes a specific Prolog predicate directly.

Here is an example demonstrating how Python loads a Prolog file and queries a validation predicate:

```python
import janus_swi as janus

# Load the Prolog rules
janus.consult("guardrails.pl")

# Execute a query with input bindings
json_input = '{"client_age": 70, "risk_tolerance": "low", "allocations": {"stocks": 40}}'
result = janus.query_once("validate_portfolio_json(Json, Errors)", {"Json": json_input})

if result:
    print("Violations:", result["Errors"])
else:
    print("Query failed.")
```

## Practical Applications

Combining Python's data-driven, machine learning libraries with Prolog's logic-driven, symbolic capabilities opens up several practical neuro-symbolic AI architectures:

### 1. LLM Guardrails & Compliance
Large Language Models (LLMs) excel at processing natural language, but struggle to guarantee compliance with exact logical bounds (e.g. regulatory rules, compliance math, and safety boundaries). By feeding the structured (JSON) output of an LLM into an embedded Prolog instance running `janus_swi`, you can enforce strict, mathematical logic checks on the output before displaying it to a user. If violations are found, the Prolog-generated error explanations can be fed back into the LLM's prompt to prompt self-correction.

### 2. Constraint-Guided Optimization
Python libraries can be used to scrape data, poll live web APIs, or preprocess images and speech, translating the raw data into structured facts. Prolog's Constraint Logic Programming (CLP) packages, such as `clpfd` or `clpb`, can then ingest these facts to solve highly complex scheduling, resource allocation, or routing problems, returning the optimal solution to the Python controller.

### 3. Explainable Machine Learning (XAI)
Deep learning models are notoriously hard to audit. In a hybrid system, you can use Python to execute a neural model (such as a neural classifier or object detector) and pass its confidence scores into Prolog. Prolog can then combine these statistical detections with a symbolic rule system to construct a clear, human-understandable explanation or justification of the final decision.
