:- module(test_json, []).
:- use_module(library(plunit)).
:- use_module('../prolog/json_utils').

:- begin_tests(json_utils).

test(parse_json) :-
    parse_json_string('{"name":"test","value":42}', Dict),
    is_dict(Dict).

:- end_tests(json_utils).
