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

%% TBD: Create companion Python file sklearn_bridge.py
