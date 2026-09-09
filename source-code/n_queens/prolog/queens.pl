%% queens.pl - N-Queens solver using CLP(FD)
:- module(queens, [
    n_queens/2,
    n_queens/3
]).

:- use_module(library(clpfd)).

%% n_queens(+N:int, -Queens:list) is nondet
%% Queens is a list of column positions for queens in each row.
n_queens(N, Queens) :-
    n_queens(N, [], Queens).

%% n_queens(+N:int, +Options:list, -Queens:list) is nondet
%% Options:
%%   ff_opt(true)  label with labeling([ff], Queens)
%%                 (first-fail heuristic); otherwise label/1 is used.
n_queens(N, Options, Queens) :-
    length(Queens, N),
    Queens ins 1..N,
    safe_queens(Queens),
    (   member(ff_opt(true), Options)
    ->  labeling([ff], Queens)
    ;   label(Queens)
    ).

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
