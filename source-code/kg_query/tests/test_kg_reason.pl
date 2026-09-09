:- module(test_kg_reason, []).
:- use_module(library(plunit)).
:- use_module('../prolog/kg_reason').
:- use_module('../prolog/sample_data').   % exports load_sample_data/0

:- begin_tests(kg_reason).

test(direct_relation, [nondet]) :-
    relation(mark, uses, prolog).

test(reverse_relation, [nondet]) :-
    relation(prolog, implemented_by, swi).

test(entity_type_person, [nondet]) :-
    entity(mark, person).

test(entity_type_language, [nondet]) :-
    entity(prolog, language).

test(entity_type_field, [nondet]) :-
    entity(ai, field).

test(multi_hop_path, [nondet]) :-
    path(mark, swi, Path),
    length(Path, N),
    N >= 2.

test(connected_entities, [nondet]) :-
    connected(mark, swi).

test(three_hop_path, [nondet]) :-
    path(mark, cpython, Path),
    length(Path, N),
    N >= 3.

test(connected_via_collaboration, [nondet]) :-
    connected(mark, chen).

test(relation_count_uses_positive) :-
    relation_count(uses, Count),
    Count > 0.

test(reachable_from_mark_includes_swi, [nondet]) :-
    reachable(mark, Reachable),
    member(swi, Reachable).

test(neighbors_of_mark_includes_ai, [nondet]) :-
    neighbors(mark, Neighbors, _),
    member(ai, Neighbors).

test(multi_hop_via_organizations, [nondet]) :-
    path(sarah, gemma, Path),
    length(Path, N),
    N >= 2.

test(dialect_chain_clojure_lisp, [nondet]) :-
    path(clojure, lisp, Path),
    length(Path, N),
    N >= 2.

test(connected_persons_via_field, [nondet]) :-
    connected(sarah, ivan).

test(entity_count_is_132) :-
    aggregate_all(count, entity_of_type(_, _), 132).

test(relation_count_is_242) :-
    aggregate_all(count, relates(_, _, _), 242).

test(total_facts_374) :-
    aggregate_all(count, (entity(_, _) ; relation(_, _, _)), 374).

test(load_twice_no_duplicates) :-
    load_sample_data,
    load_sample_data,
    aggregate_all(count, entity(_, _), 132).

test(depth_limited_path) :-
    path(mark, swi, Path, 4),
    length(Path, Len),
    Len >= 2, Len =< 5.

test(depth_limit_blocks_long_path, [fail]) :-
    path(mark, cpython, _, 1).

test(path_person_to_project, [nondet]) :-
    path(sarah, bert, _).

test(connected_person_to_concept, [nondet]) :-
    connected(mark, unification).

test(path_language_to_field, [nondet]) :-
    path(ai, prolog, _).

test(path_organization_to_concept, [nondet]) :-
    path(google, transformer, _).

test(dialect_chain_racket_lisp, [nondet]) :-
    path(racket, lisp, Path),
    length(Path, N),
    N >= 2.

test(field_subfield_chain, [nondet]) :-
    path(dl, ai, Path),
    length(Path, N),
    N >= 2,
    !.

test(all_paths_not_empty, [nondet]) :-
    all_paths(mark, swi, Paths),
    Paths \= [].

test(path_no_cycles, [nondet]) :-
    path(mark, swi, Path),
    sort(Path, Uniq),
    length(Path, N),
    length(Uniq, N).

test(reachable_symmetry, [nondet]) :-
    connected(sarah, bert),
    connected(bert, sarah).

:- end_tests(kg_reason).