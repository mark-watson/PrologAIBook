%% json_utils.pl - JSON parsing and generation utilities
:- module(json_utils, [
    parse_json_string/2,
    json_to_prolog/2
]).

:- use_module(library(http/json)).

%% parse_json_string(+JsonString, -PrologTerm)
parse_json_string(JsonString, Term) :-
    atom_json_dict(JsonString, Term, []).

%% json_to_prolog(+JsonDict, -PrologFacts)
%% Convert a JSON dict to a list of key-value pairs
json_to_prolog(Dict, Pairs) :-
    is_dict(Dict),
    dict_pairs(Dict, _, Pairs).
