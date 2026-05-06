%% read_graph.pl - Utility to read graph data from sample_graph.txt
:- module(read_graph, [
    load_graph/0,
    load_graph/1,
    edge/2
]).

:- dynamic edge/2.

%% load_graph/0 - Load graph from default file (sample_graph.txt)
load_graph :-
    source_file(read_graph:_, SrcFile),
    file_directory_name(SrcFile, PrologDir),
    file_directory_name(PrologDir, ProjectDir),
    atom_concat(ProjectDir, '/sample_graph.txt', DefaultFile),
    load_graph(DefaultFile).

%% load_graph/1 - Load graph from a specified file
%%   Reads lines of the form:  edge(Source, Destination).
%%   Asserts each as an edge/2 fact.
load_graph(File) :-
    retractall(edge(_, _)),
    open(File, read, Stream),
    read_edges(Stream),
    close(Stream).

read_edges(Stream) :-
    read_term(Stream, Term, []),
    (   Term == end_of_file
    ->  true
    ;   assert_edge(Term),
        read_edges(Stream)
    ).

assert_edge(edge(From, To)) :-
    !,
    assertz(edge(From, To)).
assert_edge(_).   % skip comments / unrecognised terms
