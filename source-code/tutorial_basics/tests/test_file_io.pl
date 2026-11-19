:- module(test_file_io, []).
:- use_module(library(plunit)).
:- use_module('../prolog/file_io').

:- begin_tests(file_io).

test(read_all_terms) :-
    read_file_terms('data/people.pl', Terms),
    assertion(Terms == [person(tom, 62), person(bob, 38),
                        likes(bob, chess)]).

test(read_file_prints, [true(Out == "Read term: person(tom,62)\nRead term: person(bob,38)\nRead term: likes(bob,chess)\n")]) :-
    with_output_to(string(Out), read_file('data/people.pl')).

test(missing_file, [error(existence_error(source_sink, _))]) :-
    read_file_terms('data/no_such_file.pl', _).

:- end_tests(file_io).
