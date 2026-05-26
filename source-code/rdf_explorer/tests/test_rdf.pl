:- module(test_rdf, []).
:- use_module(library(plunit)).
:- use_module('../prolog/rdf_loader').

:- begin_tests(rdf_loader).

test(load_and_query) :-
    load_rdf_file('example.ttl'),
    query_rdf(S, 'http://www.w3.org/2000/01/rdf-schema#label', literal('SWI-Prolog')),
    S = 'http://example.org/swi_prolog',
    !.

:- end_tests(rdf_loader).
