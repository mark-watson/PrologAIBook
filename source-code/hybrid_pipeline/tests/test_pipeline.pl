:- module(test_pipeline, []).
% The Makefile runs us from the project root; silence the deprecated
% CWD-relative use_module warning for the prolog/ directory.
:- set_prolog_flag(source_search_working_directory, true).
:- use_module(library(plunit)).

% --- Janus / mock bootstrap ---
%
% install_janus_or_mock/0 is defined up-front so the directive below
% runs BEFORE prolog/pipeline is loaded.  On machines where janus.so
% cannot resolve Python3.framework (see README "Troubleshooting"),
% loading library(janus) fails with a dlopen error; in that case the
% mock in tests/mock_janus.pl is consulted first so the pipeline's
% symbolic layer can still be exercised fully offline.  When Janus
% loads, the real py_call/2 is used and spaCy (or the rule-based
% fallback inside nlp_bridge.py) provides the entities.

install_janus_or_mock :-
    catch(use_module(library(janus)), _, fail),
    current_predicate(janus:py_call/2),
    !.
install_janus_or_mock :-
    % Fallback path: consult the mock from this file's directory so the
    % Makefile works from any CWD.
    once(source_file(install_janus_or_mock, ThisFile)),
    file_directory_name(ThisFile, TDir),
    atomic_list_concat([TDir, '/mock_janus.pl'], MockFile),
    exists_file(MockFile),
    !,
    abolish(janus:py_call/2),
    consult(MockFile),
    format(user_error,
        "~n[test_pipeline] Janus unavailable; using mock py_call~n",
        []).
install_janus_or_mock :-
    print_message(warning,
        format('mock_janus.pl not found next to test file', [])).

:- install_janus_or_mock.

:- use_module(prolog/pipeline).

:- begin_tests(pipeline).

% Works in every environment: at least the mocked entities must appear.
% With spaCy installed we expect the same PERSON/GPE conclusions, since
% the mock fallback recognises the same names in this sentence.
test(run_pipeline_success) :-
    run_pipeline("John Smith visited London last week", Result),
    Result = pipeline_result(_, Conclusions),
    % Verify that we extracted at least an important person and a location
    member(conclusion(_, important_person), Conclusions),
    member(conclusion(_, location), Conclusions),
    !.

% Exercise the fallback extraction bridge explicitly so coverage does
% not depend on whether spaCy happens to be installed.
test(python_fallback_mock_entities) :-
    mock_entity_list("John Smith visited London", Entities),
    [E1, E2, E3] = Entities,
    % Janus converts Python str to Prolog atoms by default, and the
    % Prolog mock mirrors that.
    E1 = _{text: 'John',   label: 'PERSON'},
    E2 = _{text: 'Smith',  label: 'PERSON'},
    E3 = _{text: 'London', label: 'GPE'}.

test(state_cleaned_between_runs, [true(Conclusions2 == Conclusions1)]) :-
    run_pipeline("John Smith visited London last week",
                 pipeline_result(_, Conclusions1)),
    run_pipeline("John Smith visited London last week",
                 pipeline_result(_, Conclusions2)).

current_pipeline_mock_active :-
    \+ current_predicate(janus:py_iter/2),      % py_iter/2 only exists
                                                % when the Janus foreign
                                                % library initialised
    current_predicate(mock_py_entities/2).

% mock_entity_list(+Text, -Entities) is det.  Dispatches to the Python
% mock via Janus when available, else to the Prolog mirror consulted
% from tests/mock_janus.pl, so the shape check runs in both
% environments.
mock_entity_list(Text, Entities) :-
    (   current_pipeline_mock_active
    ->  mock_py_entities(Text, Entities)
    ;   py_call(nlp_bridge:mock_entities(Text), Entities)
    ).

:- end_tests(pipeline).
