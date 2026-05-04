%% pipeline.pl - Hybrid AI pipeline: Python preprocessing + Prolog reasoning
:- module(pipeline, [
    run_pipeline/2
]).

:- use_module(library(janus)).

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
    findall(conclusion(E, Type), entity_conclusion(E, Type), Conclusions),
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
