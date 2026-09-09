%% read_graph.pl - Utility to read graph data from sample_graph.txt
:- module(read_graph, [
    load_graph/0,
    load_graph/1,
    clear_graph/0,
    edge/2
]).

:- dynamic edge/2.

%% clear_graph/0 - Remove all loaded edge/2 facts.
clear_graph :-
    retractall(edge(_, _)).

%% load_graph/0 - Load graph from default file (sample_graph.txt
%% located next to this pack's prolog/ directory).
load_graph :-
    source_file(read_graph:edge(_, _), SrcFile),
    file_directory_name(SrcFile, PrologDir),
    file_directory_name(PrologDir, ProjectDir),
    atomic_list_concat([ProjectDir, '/sample_graph.txt'], DefaultFile),
    load_graph(DefaultFile).

%% load_graph/1 - Load graph from a specified file
%%   Reads lines of the form:  edge(Source, Destination).
%%   Clears any previously loaded edges first.  Malformed terms
%%   are counted and reported as a warning when reading finishes.
load_graph(File) :-
    clear_graph,
    setup_call_cleanup(
        open(File, read, Stream),
        read_edges(Stream, 0, Skipped),
        close(Stream)
    ),
    (   Skipped > 0
    ->  print_message(warning, read_graph_skipped(Skipped))
    ;   true
    ).

read_edges(Stream, Skip0, Skip) :-
    read_term(Stream, Term, []),
    (   Term == end_of_file
    ->  Skip = Skip0
    ;   (   Term = edge(From, To)
        ->  assertz(edge(From, To)),
            Skip1 = Skip0
        ;   Skip1 is Skip0 + 1
        ),
        read_edges(Stream, Skip1, Skip)
    ).
