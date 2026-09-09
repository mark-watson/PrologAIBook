%% rdf_loader.pl - Load and query RDF data using SWI-Prolog's semweb
%% library
:- module(rdf_loader, [
    load_rdf_file/1,
    query_rdf/3,
    list_subjects/0,
    describe_resource/1,
    subjects/1,
    triples_of/2
]).

:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/turtle)).

%% load_rdf_file(+FilePath) - Load RDF from Turtle or RDF/XML file
%% Relative paths are resolved against the calling source file's
%% directory when possible, so tests/examples are CWD-independent.
load_rdf_file(FilePath) :-
    (   absolute_file_name(FilePath, Abs, [access(read)])
    ->  true
    ;   prolog_load_context(source, Source),
        file_directory_name(Source, Dir),
        atomic_list_concat([Dir, '/', FilePath], Candidate),
        absolute_file_name(Candidate, Abs, [access(read)])
    ),
    rdf_load(Abs).

%% query_rdf(?S, ?P, ?O) - Query the RDF triplestore
query_rdf(S, P, O) :- rdf(S, P, O).

%% subjects(-Subjects) - Return the sorted list of unique subjects
subjects(Subjects) :-
    setof(S, P^O^rdf(S, P, O), Subjects).

%% triples_of(+URI, -Triples) - Return P-O pairs for a subject
triples_of(URI, Triples) :-
    findall(P-O, rdf(URI, P, O), Triples).

%% list_subjects - Print all unique subjects
list_subjects :-
    subjects(Subjects),
    forall(member(S, Subjects), format("  ~w~n", [S])).

%% describe_resource(+URI) - Print all triples for a given subject
describe_resource(URI) :-
    format("Describing: ~w~n", [URI]),
    triples_of(URI, Triples),
    forall(
        member(P-O, Triples),
        format("  ~w -> ~w~n", [P, O])
    ).
