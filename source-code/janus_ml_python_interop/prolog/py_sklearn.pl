%% py_sklearn.pl - Call scikit-learn from Prolog via Janus
:- module(py_sklearn, [
    py_classify/3,
    py_cluster/3
]).

:- use_module(library(janus)).

% Resolve the companion python/ directory relative to this source file
% so the module works from any current working directory.
:- initialization(setup_python_path, main).

setup_python_path :-
    once(source_file(py_sklearn:_, ThisFile)),
    file_directory_name(ThisFile, PrologDir),
    atom_concat(PrologDir, '/../python', PyDir),
    py_add_lib_dir(PyDir).

%% py_classify(+TrainData, +TestData, -Predictions)
%% Uses scikit-learn's DecisionTreeClassifier via Janus.
%% TrainData rows are labelled:  [[f1, ..., fN, label], ...].
%% TestData rows may be given WITHOUT a trailing dummy label; if a test
%% row is one element shorter than a training row a dummy 0 label is
%% appended internally before calling Python, which keeps backwards
%% compatibility with the old calling convention.
py_classify(TrainData, TestData, Predictions) :-
    TrainData = [TrainRow|_],
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
