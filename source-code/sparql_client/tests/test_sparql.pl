:- module(test_sparql, []).
:- use_module(library(plunit)).
:- use_module('../prolog/sparql').

:- begin_tests(sparql).

%% Offline tests for the SPARQL quoting helpers.  Live endpoint
%% queries (Wikidata demo) are documented in README.md.

test(sparql_literal_plain) :-
    sparql_literal('hello world', Q),
    assertion(Q == '"hello world"').

test(sparql_literal_escapes_quote) :-
    name(Atom, [97, 34, 98]),        % = a"b
    sparql_literal(Atom, Q),
    name(Q, Codes),
    assertion(Codes == [34, 97, 92, 34, 98, 34]).   % "a\"b"

test(sparql_literal_escapes_backslash) :-
    name(Atom, [97, 92, 98]),        % = a\b
    sparql_literal(Atom, Q),
    name(Q, Codes),
    assertion(Codes == [34, 97, 92, 92, 98, 34]).   % "a\\b"

test(sparql_iri_wraps_in_angles) :-
    sparql_iri('http://www.wikidata.org/entity/Q42', IRI),
    assertion(IRI == '<http://www.wikidata.org/entity/Q42>').

:- end_tests(sparql).
