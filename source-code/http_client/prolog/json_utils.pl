%% json_utils.pl - JSON parsing and generation utilities
:- module(json_utils, [
    parse_json_string/2,
    json_dict_pairs/2,
    json_to_prolog/2
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

%% json_to_prolog(+JsonDict, -Pairs)
%% Deprecated alias for json_dict_pairs/2, kept for compatibility.
json_to_prolog(Dict, Pairs) :-
    print_message(warning, deprecated(json_to_prolog/2,
                                      json_dict_pairs/2)),
    json_dict_pairs(Dict, Pairs).

:- multifile prolog:message//1.

prolog:message(deprecated(Old, New)) -->
    ['json_utils: ~w is deprecated, use ~w instead'-[Old, New]].
