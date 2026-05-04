:- module(test_queens, []).
:- use_module(library(plunit)).
:- use_module('../prolog/queens').

:- begin_tests(queens).

test(four_queens) :-
    n_queens(4, Queens),
    length(Queens, 4).

test(eight_queens) :-
    n_queens(8, Queens),
    length(Queens, 8).

:- end_tests(queens).
