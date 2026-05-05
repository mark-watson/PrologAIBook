# Constraint Logic Programming

Constraint Logic Programming (CLP) extends Prolog with the ability to reason about constraints over various domains — integers, reals, and finite domains. SWI-Prolog provides excellent CLP libraries that make it possible to solve complex combinatorial and optimization problems declaratively.

## Introduction to CLP

TBD: What constraints are, how they differ from ordinary Prolog goals, and why CLP is powerful for AI.

## CLP(FD): Constraints over Finite Domains

TBD: Using `library(clpfd)` for integer constraint problems. The `#=`, `#\=`, `#<`, `#>`, `in/2`, and `label/1` predicates.

## Solving Sudoku with CLP(FD)

TBD: A concise, elegant Sudoku solver demonstrating the power of constraint propagation.

The **sudoku_solver** project provides a complete solver in under 30 lines of logic. Here is the file **sudoku_solver/prolog/sudoku.pl**:

```prolog
%% sudoku.pl - Sudoku solver using CLP(FD) constraints
:- module(sudoku, [sudoku/1, print_board/1]).

:- use_module(library(clpfd)).

%% sudoku(+Rows) - Solve a 9x9 Sudoku puzzle
sudoku(Rows) :-
    length(Rows, 9),
    maplist(same_length(Rows), Rows),
    append(Rows, Vs), Vs ins 1..9,
    maplist(all_distinct, Rows),
    transpose(Rows, Columns),
    maplist(all_distinct, Columns),
    Rows = [As,Bs,Cs,Ds,Es,Fs,Gs,Hs,Is],
    blocks(As, Bs, Cs),
    blocks(Ds, Es, Fs),
    blocks(Gs, Hs, Is),
    maplist(label, Rows).

blocks([], [], []).
blocks([N1,N2,N3|Ns1], [N4,N5,N6|Ns2], [N7,N8,N9|Ns3]) :-
    all_distinct([N1,N2,N3,N4,N5,N6,N7,N8,N9]),
    blocks(Ns1, Ns2, Ns3).

%% print_board(+Rows) - Pretty-print a solved board
print_board([]).
print_board([Row|Rows]) :-
    format("~w~n", [Row]),
    print_board(Rows).
```

## The N-Queens Problem

TBD: Solving N-Queens as a constraint satisfaction problem. Comparing a naive backtracking solution with a CLP(FD) solution.

The **n_queens** project solves the problem using CLP(FD) diagonal constraints. Here is the file **n_queens/prolog/queens.pl**:

```prolog
%% queens.pl - N-Queens solver using CLP(FD)
:- module(queens, [n_queens/2]).

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
```

## Scheduling and Resource Allocation

TBD: Modeling real-world scheduling problems (e.g., job-shop scheduling, meeting room allocation) as constraint satisfaction problems.

The **job_scheduler** project models scheduling with temporal constraints. Here is the file **job_scheduler/prolog/scheduler.pl**:

```prolog
%% scheduler.pl - Job scheduling with temporal constraints using CLP(FD)
:- module(scheduler, [schedule_jobs/2]).

:- use_module(library(clpfd)).

%% schedule_jobs(+Jobs, -Schedule)
%% Jobs: list of job(Name, Duration, Deadline) terms
%% Schedule: list of scheduled(Name, Start, End) terms
schedule_jobs(Jobs, Schedule) :-
    maplist(create_task, Jobs, Schedule, Starts),
    chain(Starts, #=<),  % order tasks by start time
    maplist(deadline_constraint, Jobs, Schedule),
    no_overlap(Schedule),
    maplist(label_task, Schedule).

create_task(job(Name, Duration, _Deadline),
            scheduled(Name, Start, End), Start) :-
    Start in 0..100,
    End #= Start + Duration.

deadline_constraint(job(Name, _Duration, Deadline),
                    scheduled(Name, _Start, End)) :-
    End #=< Deadline.

no_overlap([]).
no_overlap([_]).
no_overlap([scheduled(_,_,End1)|Rest]) :-
    Rest = [scheduled(_,Start2,_)|_],
    End1 #=< Start2,
    no_overlap(Rest).

label_task(scheduled(_, Start, _)) :- label([Start]).
```

## CLP(R) and CLP(Q): Constraints over Reals and Rationals

TBD: Using `library(clpr)` and `library(clpq)` for continuous constraint problems. Applications in engineering and optimization.

## CLP(B): Boolean Constraints

TBD: Using `library(clpb)` for Boolean satisfiability problems and combinatorial verification.
