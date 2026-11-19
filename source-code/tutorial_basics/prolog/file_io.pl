%% file_io.pl - Reading Prolog terms from a file
%% Demonstrates: streams, read/2, end_of_file, recursion

:- module(file_io, [
    read_file/1,
    read_file_terms/2
]).

%% read_file(+Path)
%% Print each term in the file at Path.
read_file(Path) :-
    open(Path, read, Stream),
    read_terms(Stream),
    close(Stream).

read_terms(Stream) :-
    read(Stream, Term),
    (   Term == end_of_file
    ->  true
    ;   format('Read term: ~w~n', [Term]),
        read_terms(Stream)
    ).

%% read_file_terms(+Path, -Terms)
%% Collect the terms in the file at Path into a list. setup_call_cleanup/3
%% closes the stream even if reading throws a syntax error.
read_file_terms(Path, Terms) :-
    setup_call_cleanup(
        open(Path, read, Stream),
        collect_terms(Stream, Terms),
        close(Stream)).

collect_terms(Stream, Terms) :-
    read(Stream, Term),
    (   Term == end_of_file
    ->  Terms = []
    ;   Terms = [Term|Rest],
        collect_terms(Stream, Rest)
    ).
