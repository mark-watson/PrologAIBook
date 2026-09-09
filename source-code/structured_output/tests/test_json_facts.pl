:- module(test_json_facts, []).
:- use_module(library(plunit)).
:- use_module('../prolog/json_to_facts').

:- begin_tests(json_to_facts, [setup(clear_extracted),
                               cleanup(clear_extracted)]).

test(parse_entities) :-
    json_string_to_facts(
        '{"entities":[{"name":"Paris","type":"city"}]}'),
    extracted_entity("Paris", "city").

test(parse_entities_and_relations) :-
    json_string_to_facts(
        '{"entities":[
            {"name":"Paris","type":"city"},
            {"name":"France","type":"country"}],
          "relations":[
            {"subject":"Paris","predicate":"locatedIn","object":"France"}]}'),
    extracted_entity("Paris", "city"),
    extracted_entity("France", "country"),
    extracted_relation("Paris", "locatedIn", "France").

test(counts_variant_returns_data) :-
    json_string_to_facts(
        '{"entities":[
            {"name":"Paris","type":"city"},
            {"name":"Rome","type":"city"}],
          "relations":[
            {"subject":"Paris","predicate":"hasAirport","object":"CDG"}]}',
        Counts),
    Counts.entities == 2,
    Counts.relations == 1,
    Counts.entities_with_warnings == 0,
    Counts.relations_with_warnings == 0.

test(malformed_json_yields_error) :-
    catch(json_string_to_facts('{not valid json'),
          error(syntax_error(_), _),
          true).

test(missing_entity_key_warns_and_skips) :-
    % One well-formed entity plus one missing its "name" key: the
    % malformed item must be skipped (with a warning) and the good one
    % still asserted.  The warning goes to the terminal — visible, not
    % fatal.
    json_string_to_facts(
        '{"entities":[
            {"name":"Paris","type":"city"},
            {"type":"city"}]}',
        Counts),
    Counts.entities == 1,
    Counts.entities_with_warnings == 1,
    Counts.relations == 0,
    Counts.relations_with_warnings == 0,
    extracted_entity("Paris", "city").

test(missing_relation_key_warns_and_skips) :-
    json_string_to_facts(
        '{"relations":[
            {"subject":"Paris","predicate":"locatedIn"},
            {"subject":"Rome","predicate":"locatedIn","object":"Italy"}]}',
        Counts),
    Counts.relations == 1,
    Counts.relations_with_warnings == 1,
    extracted_relation("Rome", "locatedIn", "Italy").

test(clear_extracted_empties_store) :-
    json_string_to_facts(
        '{"entities":[{"name":"Paris","type":"city"}]}'),
    clear_extracted,
    \+ extracted_entity(_, _),
    \+ extracted_relation(_, _, _).

:- end_tests(json_to_facts).
