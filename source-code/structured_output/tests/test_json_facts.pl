:- module(test_json_facts, []).
:- use_module(library(plunit)).
:- use_module('../prolog/json_to_facts').

:- begin_tests(json_to_facts).

test(parse_entities, [cleanup(retractall(extracted_entity(_,_)))]) :-
    json_string_to_facts('{"entities":[{"name":"Paris","type":"city"}]}'),
    extracted_entity("Paris", "city").

:- end_tests(json_to_facts).
