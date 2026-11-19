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
