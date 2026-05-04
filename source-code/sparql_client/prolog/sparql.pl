%% sparql.pl - SPARQL client for querying remote endpoints
:- module(sparql, [
    sparql_query_dbpedia/2,
    sparql_query_wikidata/2,
    sparql_query/3
]).

:- use_module(library(semweb/sparql_client)).
:- use_module(library(http/http_client)).

%% sparql_query_dbpedia(+Query, -Results)
sparql_query_dbpedia(Query, Results) :-
    sparql_query(Query, Results,
                 [host('dbpedia.org'), path('/sparql')]).

%% sparql_query_wikidata(+Query, -Results)
sparql_query_wikidata(Query, Results) :-
    sparql_query(Query, Results,
                 [host('query.wikidata.org'), path('/sparql')]).

%% TBD: Add helper predicates for common query patterns
