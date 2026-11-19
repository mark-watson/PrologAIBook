:- module(test_kg, []).
:- use_module(library(plunit)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdf_ntriples)).
:- use_module('../prolog/kg_builder').
:- use_module('../prolog/kg_enrich').

:- begin_tests(kg_builder, [cleanup(clear_all_triples)]).

with_tmp_file(_Ext, File, Goal) :-
    tmp_file_stream(text, File, S0),
    close(S0),
    setup_call_cleanup(true, Goal, delete_file(File)).

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
    with_tmp_file(nt, F,
        ( export_rdf(F),
          read_file_to_string(F, Content, []) )),
    assertion(sub_string(Content, _, _, _, "\\\"quoted\\\"")),
    !.

test(export_rdf_resource_and_literal) :-
    clear_all_triples,
    add_triple(john, works_at, acme),
    add_triple(john, age, 42),
    with_tmp_file(nt, F,
        ( export_rdf(F, 'http://example.org/kg/'),
          read_file_to_string(F, Content, []) )),
    split_string(Content, "\n", "", Lines),
    assertion(memberchk("<http://example.org/kg/john> <http://example.org/kg/works_at> <http://example.org/kg/acme> .", Lines)),
    assertion(memberchk("<http://example.org/kg/john> <http://example.org/kg/age> \"42\" .", Lines)).

test(export_rdf_is_valid_ntriples) :-
    clear_all_triples,
    add_triple(john, works_at, acme),
    add_triple(doc1, has_title, 'line one\nline "two"'),
    with_tmp_file(nt, F,
        ( export_rdf(F),
          rdf_read_ntriples(F, Triples, []) )),
    length(Triples, 2),
    assertion(memberchk(rdf(_, _, literal('line one\nline "two"')),
                        Triples)).

test(export_rdf_invalid_iri_fails, [fail]) :-
    clear_all_triples,
    add_triple('not a valid iri', rel, obj),
    with_tmp_file(nt, F, export_rdf(F)).

test(export_cypher_backtick_quoting) :-
    clear_all_triples,
    add_triple('we`ird', rel, obj),
    with_tmp_file(cypher, F,
        ( export_cypher(F),
          read_file_to_string(F, Content, []) )),
    assertion(sub_string(Content, _, _, _, "``")),
    !.

:- end_tests(kg_builder).

:- begin_tests(kg_enrich, [cleanup(clear_all_triples)]).

test(literal_forms) :-
    literal_text(literal(lang(en, 'Ada')), A),
    literal_text(literal(type(xsd:string, 'Bob')), B),
    literal_text(literal('Cy'), C),
    assertion([A, B, C] == ['Ada', 'Bob', 'Cy']).

test(local_answer_needs_no_network) :-
    clear_all_triples,
    add_triple(prolog, designed_by, 'Alain Colmerauer'),
    findall(D, query_designer(prolog, D), Ds),
    assertion(Ds == ['Alain Colmerauer']).

:- end_tests(kg_enrich).
