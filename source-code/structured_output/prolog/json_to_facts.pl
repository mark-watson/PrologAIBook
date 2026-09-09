%% json_to_facts.pl - Convert structured LLM JSON output into Prolog
%% facts
:- module(json_to_facts, [
    json_string_to_facts/1,     % +JsonString
    json_string_to_facts/2,     % +JsonString, -Counts
    clear_extracted/0,          %
    extracted_entity/2,
    extracted_relation/3
]).

:- use_module(library(json)).

:- dynamic extracted_entity/2.    % extracted_entity(Name, Type)
:- dynamic extracted_relation/3.  % extracted_relation(Subject,
                                  %            Predicate, Object)

%% clear_extracted/0
%% Remove every asserted entity/relation fact (test setup helper).
clear_extracted :-
    retractall(extracted_entity(_, _)),
    retractall(extracted_relation(_, _, _)).

%% json_string_to_facts(+JsonString)
%% Parses JSON with entities/relations arrays into Prolog facts
json_string_to_facts(JsonString) :-
    json_string_to_facts(JsonString, _Counts).

%% json_string_to_facts(+JsonString, -Counts)
%% As /1 but also returns a counts dict:
%%   _{entities: NE, entities_with_warnings: WE,
%%     relations: NR, relations_with_warnings: WR}.
%% Malformed items are skipped with a print_message/2 warning and
%% counted, never thrown.
json_string_to_facts(JsonString, Counts) :-
    atom_json_dict(JsonString, Dict, []),
    (   get_dict(entities, Dict, Entities)
    ->  foldl(assert_entity, Entities, 0-0, NE-WE)
    ;   NE = 0, WE = 0
    ),
    (   get_dict(relations, Dict, Relations)
    ->  foldl(assert_relation, Relations, 0-0, NR-WR)
    ;   NR = 0, WR = 0
    ),
    Counts = _{ entities: NE, entities_with_warnings: WE,
                relations: NR, relations_with_warnings: WR }.

assert_entity(E, N0-W0, N-W) :-
    (   get_dict(name, E, Name), get_dict(type, E, Type)
    ->  (   \+ extracted_entity(Name, Type)
        ->  assert(extracted_entity(Name, Type))
        ;   true
        ),
        N is N0 + 1, W = W0
    ;   print_message(warning,
            malformed_entity_skipped(E)),
        N = N0, W is W0 + 1
    ).

assert_relation(R, N0-W0, N-W) :-
    (   get_dict(subject, R, S),
        get_dict(predicate, R, P),
        get_dict(object, R, O)
    ->  (   \+ extracted_relation(S, P, O)
        ->  assert(extracted_relation(S, P, O))
        ;   true
        ),
        N is N0 + 1, W = W0
    ;   print_message(warning,
            malformed_relation_skipped(R)),
        N = N0, W is W0 + 1
    ).

% Rendering for our custom warning terms.
:- multifile prolog:message//1.
prolog:message(malformed_entity_skipped(E)) -->
    ['json_to_facts: skipping entity with missing keys: ~w'-[E]].
prolog:message(malformed_relation_skipped(R)) -->
    ['json_to_facts: skipping relation with missing keys: ~w'-[R]].
