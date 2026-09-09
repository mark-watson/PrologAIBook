:- module(test_queens, []).
:- use_module(library(plunit)).
:- use_module('../prolog/queens').

:- begin_tests(queens).

test(four_queens, [nondet]) :-
    n_queens(4, Queens),
    length(Queens, 4).

test(eight_queens, [nondet]) :-
    n_queens(8, Queens),
    length(Queens, 8).

test(four_queens_valid, [nondet]) :-
    n_queens(4, Queens),
    valid_solution(4, Queens).

test(four_queens_two_solutions) :-
    aggregate_all(count, n_queens(4, _), 2).

test(eight_queens_valid, [nondet]) :-
    n_queens(8, Queens),
    valid_solution(8, Queens).

test(four_queens_ff, [nondet]) :-
    n_queens(4, [ff_opt(true)], Queens),
    valid_solution(4, Queens).

test(eight_queens_ff_count) :-
    aggregate_all(count, n_queens(8, [ff_opt(true)], _), 92).

:- end_tests(queens).

%% valid_solution(+N, +Queens) - verify no two queens attack
%% each other. Queens is a ground list of N column positions
%% (row i is in column Queens[i]), all in 1..N and pairwise
%% non-attacking.
valid_solution(N, Queens) :-
    length(Queens, N),
    maplist(between_(1, N), Queens),
    forall(
        (   nth1(I, Queens, Qi),
            nth1(J, Queens, Qj),
            I < J
        ),
        (   Qi =\= Qj,                     % different column
            abs(Qi - Qj) =\= J - I         % different diagonal
        )
    ).

between_(Lo, Hi, X) :- X >= Lo, X =< Hi.
