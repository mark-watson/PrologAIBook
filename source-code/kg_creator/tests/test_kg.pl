:- module(test_kg, []).
:- use_module(library(plunit)).
:- use_module('../prolog/kg_builder').

:- begin_tests(kg_builder).

test(add_and_query) :-
    clear_all_triples,
    add_triple(john, works_at, acme),
    query_triples(john, works_at, acme).

test(no_duplicates) :-
    clear_all_triples,
    add_triple(john, works_at, acme),
    add_triple(john, works_at, acme),
    findall(_, query_triples(john, works_at, acme), Results),
    length(Results, 1).

test(export_rdf_escapes_quotes) :-
    clear_all_triples,
    add_triple(doc1, has_title, 'a "quoted" title'),
    export_rdf('/tmp/kg_export_test.nt'),
    read_file_to_string('/tmp/kg_export_test.nt', Content, []),
    sub_string(Content, _, _, _, '\\"').

test(export_rdf_invalid_iri_fails, [fail]) :-
    clear_all_triples,
    add_triple('not a valid iri', rel, obj),
    export_rdf('/tmp/kg_export_bad.nt').

test(export_cypher_backtick_quoting) :-
    clear_all_triples,
    add_triples_backtick,
    export_cypher('/tmp/kg_export_test.cypher'),
    read_file_to_string('/tmp/kg_export_test.cypher', Content, []),
    sub_string(Content, _, _, _, '``').

add_triples_backtick :-
    add_triple('we`ird', rel, obj).

:- end_tests(kg_builder).
