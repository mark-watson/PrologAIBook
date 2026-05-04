%% json_to_facts.pl - Convert structured LLM JSON output into Prolog facts
:- module(json_to_facts, [
    json_string_to_facts/1,
    extracted_entity/2,
    extracted_relation/3
]).

:- use_module(library(http/json)).

:- dynamic extracted_entity/2.    % extracted_entity(Name, Type)
:- dynamic extracted_relation/3.  % extracted_relation(Subject, Predicate, Object)

%% json_string_to_facts(+JsonString)
%% Parses JSON with entities/relations arrays into Prolog facts
json_string_to_facts(JsonString) :-
    atom_json_dict(JsonString, Dict, []),
    (   get_dict(entities, Dict, Entities)
    ->  maplist(assert_entity, Entities)
    ;   true
    ),
    (   get_dict(relations, Dict, Relations)
    ->  maplist(assert_relation, Relations)
    ;   true
    ).

assert_entity(E) :-
    Name = E.name,
    Type = E.type,
    (   \+ extracted_entity(Name, Type)
    ->  assert(extracted_entity(Name, Type))
    ;   true
    ).

assert_relation(R) :-
    S = R.subject,
    P = R.predicate,
    O = R.object,
    (   \+ extracted_relation(S, P, O)
    ->  assert(extracted_relation(S, P, O))
    ;   true
    ).
