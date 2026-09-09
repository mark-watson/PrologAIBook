:- module(test_json, []).
:- use_module(library(plunit)).
:- use_module('../prolog/json_utils').

:- begin_tests(json_utils).

test(parse_json) :-
    parse_json_string('{"name":"test","value":42}', Dict),
    is_dict(Dict).

test(json_dict_pairs) :-
    parse_json_string('{"name":"test","value":42}', Dict),
    json_dict_pairs(Dict, Pairs),
    assertion(Pairs == [name-"test", value-42]).

test(json_to_prolog_alias) :-
    parse_json_string('{"name":"test"}', Dict),
    json_to_prolog(Dict, Pairs),
    assertion(Pairs == [name-"test"]).

:- end_tests(json_utils).
