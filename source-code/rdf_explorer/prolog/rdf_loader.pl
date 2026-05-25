%% rdf_loader.pl - Load and query RDF data using SWI-Prolog's semweb
%% library
:- module(rdf_loader, [
    load_rdf_file/1,
    query_rdf/3,
    list_subjects/0,
    describe_resource/1
]).

:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdfs)).
:- use_module(library(semweb/turtle)).

%% load_rdf_file(+FilePath) - Load RDF from Turtle or RDF/XML file
load_rdf_file(FilePath) :-
    rdf_load(FilePath).

%% query_rdf(?S, ?P, ?O) - Query the RDF triplestore
query_rdf(S, P, O) :- rdf(S, P, O).

%% list_subjects - Print all unique subjects
list_subjects :-
    setof(S, P^O^rdf(S, P, O), Subjects),
    forall(member(S, Subjects), format("  ~w~n", [S])).

%% describe_resource(+URI) - Print all triples for a given subject
describe_resource(URI) :-
    format("Describing: ~w~n", [URI]),
    forall(
        rdf(URI, P, O),
        format("  ~w -> ~w~n", [P, O])
    ).
