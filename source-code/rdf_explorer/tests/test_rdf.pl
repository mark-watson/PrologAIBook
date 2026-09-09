:- module(test_rdf, []).
:- use_module(library(plunit)).
:- use_module('../prolog/rdf_loader').

load_and_setup :-
    source_file(load_and_setup, File),
    file_directory_name(File, Dir),
    atomic_list_concat([Dir, '/../example.ttl'], Rel),
    absolute_file_name(Rel, Abs),
    load_rdf_file(Abs).

:- load_and_setup.

:- begin_tests(rdf_loader).

test(load_and_query) :-
    query_rdf(S, 'http://www.w3.org/2000/01/rdf-schema#label', literal('SWI-Prolog')),
    S = 'http://example.org/swi_prolog',
    !.

test(subjects_returns_list) :-
    subjects(Subjects),
    member('http://example.org/prolog', Subjects),
    member('http://example.org/swi_prolog', Subjects).

test(triples_of_returns_data) :-
    triples_of('http://example.org/swi_prolog', Triples),
    member('http://www.w3.org/2000/01/rdf-schema#label'-literal('SWI-Prolog'), Triples).

:- end_tests(rdf_loader).

cleanup_rdf :- rdf_db:rdf_reset_db.
:- at_halt(cleanup_rdf).
