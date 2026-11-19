%% sparql.pl - SPARQL client for querying remote endpoints
:- module(sparql, [
    sparql_query_dbpedia/2,
    wikidata_query/2,
    sparql_query/3,
    sparql_literal/2,
    sparql_iri/2
]).

:- use_module(library(semweb/sparql_client),
              [sparql_query/3 as sparql_client_query]).
:- use_module(library(http/http_open)).    % https support

%% sparql_query(+Query, -Row, +Options)
%% Thin wrapper over sparql_client:sparql_query/3 that adds a
%% 30-second timeout unless Options gives one. Backtracking yields one
%% row(...) term per result.
sparql_query(Query, Results, Options) :-
    (   memberchk(timeout(_), Options)
    ->  AllOptions = Options
    ;   AllOptions = [timeout(30)|Options]
    ),
    sparql_client_query(Query, Results, AllOptions).

%% sparql_query_dbpedia(+Query, -Row)
%% Query DBpedia's public endpoint. Each solution is one result row.
sparql_query_dbpedia(Query, Row) :-
    sparql_query(Query, Row,
                 [endpoint('https://dbpedia.org/sparql')]).

%% wikidata_query(+Query, -Row)
%% Query the Wikidata Query Service. Use full IRIs in the query; the
%% wd: and wdt: prefixes are predefined by the service, so they also
%% work.
wikidata_query(Query, Row) :-
    sparql_query(Query, Row,
                 [endpoint('https://query.wikidata.org/sparql')]).

%% sparql_literal(+Atom, -Quoted)
%% Safely quote an atom as a SPARQL string literal: backslashes and
%% double quotes are escaped, result wrapped in double quotes.
sparql_literal(Atom, Quoted) :-
    atom_string(Atom, Str),
    string_codes(Str, Codes),
    escape_literal_codes(Codes, EscapedCodes),
    string_codes(Escaped, EscapedCodes),
    format(atom(Quoted), '"~w"', [Escaped]).

escape_literal_codes([], []).
escape_literal_codes([0'\\|Cs], [0'\\,0'\\|Es]) :-
    !,
    escape_literal_codes(Cs, Es).
escape_literal_codes([0'"|Cs], [0'\\,0'"|Es]) :-
    !,
    escape_literal_codes(Cs, Es).
escape_literal_codes([C|Cs], [C|Es]) :-
    escape_literal_codes(Cs, Es).

%% sparql_iri(+Atom, -Quoted)
%% Wrap an atom as a SPARQL IRI reference: <...>.
sparql_iri(Atom, Quoted) :-
    format(atom(Quoted), '<~w>', [Atom]).
