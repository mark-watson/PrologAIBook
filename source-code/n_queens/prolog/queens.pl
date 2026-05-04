%% queens.pl - N-Queens solver using CLP(FD)
:- module(queens, [
    n_queens/2
]).

:- use_module(library(clpfd)).

%% n_queens(+N, -Queens)
%% Queens is a list of column positions for queens in each row
n_queens(N, Queens) :-
    length(Queens, N),
    Queens ins 1..N,
    safe_queens(Queens),
    label(Queens).

safe_queens([]).
safe_queens([Q|Qs]) :-
    safe_queen(Q, Qs, 1),
    safe_queens(Qs).

safe_queen(_, [], _).
safe_queen(Q, [Q1|Qs], D) :-
    Q #\= Q1,
    Q #\= Q1 + D,
    Q #\= Q1 - D,
    D1 #= D + 1,
    safe_queen(Q, Qs, D1).
