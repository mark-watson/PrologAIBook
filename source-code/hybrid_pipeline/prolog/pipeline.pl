%% pipeline.pl - Hybrid AI pipeline: Python preprocessing + Prolog
%% reasoning
:- module(pipeline, [
    run_pipeline/2
]).

:- use_module(library(janus)).

:- dynamic extracted/2.

% Resolve the companion python/ directory relative to this source file
% so the module works from any current working directory.
:- initialization(setup_python_path, main).

setup_python_path :-
    (   current_prolog_flag(windows, true)
    ->  Sep = '\\'
    ;   Sep = '/'
    ),
    once(source_file(pipeline:_, ThisFile)),
    file_directory_name(ThisFile, PrologDir),
    atomic_list_concat([PrologDir, '..', Sep, 'python'], PyDir),
    py_add_lib_dir(PyDir).

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
    assert(extracted(Text, Type)).

%% Only PERSON and GPE labels are mapped to conclusions; every other
%% spaCy entity label is deliberately dropped by these two clauses.
entity_conclusion(E, important_person) :-
    extracted(E, 'PERSON').
entity_conclusion(E, location) :-
    extracted(E, 'GPE').
