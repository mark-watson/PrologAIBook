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

test(dict_round_trip) :-
    dict_to_json_string(_{name:"Bob", score:95}, S),
    parse_json_string(S, D),
    assertion(D.name == "Bob"),
    assertion(D.score == 95).

:- end_tests(json_utils).
