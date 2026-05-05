# The Janus Python Bridge

SWI-Prolog's Janus library provides seamless bidirectional interoperability between Prolog and Python. This opens up the entire Python data science ecosystem — NumPy, scikit-learn, spaCy, transformers — to Prolog programs.

## Setting Up Janus

TBD: Installing the Janus bridge. Configuring Python paths. Testing the connection.

## Calling Python from Prolog

TBD: Using `py_call/2` and `py_call/3` to invoke Python functions. Passing data between Prolog terms and Python objects.

The **janus_ml** project demonstrates calling scikit-learn from Prolog. Here is the file **janus_ml/prolog/py_sklearn.pl**:

```prolog
%% py_sklearn.pl - Call scikit-learn from Prolog via Janus
:- module(py_sklearn, [py_classify/3, py_cluster/3]).

:- use_module(library(janus)).

%% py_classify(+TrainData, +TestData, -Predictions)
%% Uses scikit-learn's DecisionTreeClassifier via Janus
py_classify(TrainData, TestData, Predictions) :-
    py_call(sklearn_bridge:classify(TrainData, TestData), Predictions).

%% py_cluster(+Data, +NClusters, -Labels)
%% Uses scikit-learn's KMeans via Janus
py_cluster(Data, NClusters, Labels) :-
    py_call(sklearn_bridge:cluster(Data, NClusters), Labels).
```

## Hybrid AI Pipelines

TBD: Building pipelines that use Python for preprocessing (NER, tokenization) and Prolog for reasoning.

The **hybrid_pipeline** project combines Python NLP with Prolog reasoning. Here is the file **hybrid_pipeline/prolog/pipeline.pl**:

```prolog
%% pipeline.pl - Hybrid AI pipeline: Python preprocessing + Prolog reasoning
:- module(pipeline, [run_pipeline/2]).

:- use_module(library(janus)).

%% run_pipeline(+InputText, -Result)
run_pipeline(InputText, Result) :-
    %% Step 1: Python NER
    py_call(nlp_bridge:extract_entities(InputText), Entities),
    %% Step 2: Assert as Prolog facts
    maplist(assert_entity, Entities),
    %% Step 3: Prolog reasoning
    findall(conclusion(E, Type),
            entity_conclusion(E, Type), Conclusions),
    Result = pipeline_result(Entities, Conclusions),
    %% Cleanup
    retractall(extracted(_,_)).

:- dynamic extracted/2.

assert_entity(Entity) :-
    py_call(Entity:label_, Type),
    py_call(Entity:text, Text),
    assert(extracted(Text, Type)).

entity_conclusion(E, important_person) :- extracted(E, 'PERSON').
entity_conclusion(E, location) :- extracted(E, 'GPE').
```

## Calling Prolog from Python

TBD: Using the Janus Python module to call Prolog predicates from Python scripts. Embedding Prolog reasoning in Python applications.

## Practical Applications

TBD: Real-world examples combining Python ML with Prolog symbolic AI.
