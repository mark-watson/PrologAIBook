%% json_utils.pl - JSON parsing and generation utilities
:- module(json_utils, [
    parse_json_string/2,
    json_dict_pairs/2,
    dict_to_json_string/2
]).

:- use_module(library(json)).

%% parse_json_string(+JsonString, -PrologTerm)
parse_json_string(JsonString, Term) :-
    atom_json_dict(JsonString, Term, []).

%% json_dict_pairs(+JsonDict, -Pairs)
%% Convert a JSON dict to a list of Key-Value pairs.
json_dict_pairs(Dict, Pairs) :-
    is_dict(Dict),
    dict_pairs(Dict, _, Pairs).

%% dict_to_json_string(+Dict, -JsonString)
%% Serialize a dict as compact JSON text.
dict_to_json_string(Dict, JsonString) :-
    atom_json_dict(Atom, Dict, [width(0)]),
    atom_string(Atom, JsonString).
