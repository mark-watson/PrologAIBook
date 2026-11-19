# Constraint Logic Programming

Constraint Logic Programming (CLP) extends Prolog to reason about constraints over integers, reals, rationals, and booleans. SWI-Prolog's CLP libraries let you solve hard combinatorial and optimization problems by stating the constraints and letting a solver search.

## Introduction to CLP

Plain Prolog solves search problems with unification and backtracking. This often means **generate and test**: bind the variables to values, then check the conditions, and backtrack on failure. On large search spaces this is far too slow.

**Constraint Logic Programming** reverses the order to **constrain, then generate**:
1. **Constraints** are relations that limit the values (the *domain*) each variable can take.
2. The **constraint solver** keeps these relations. When one variable's domain shrinks, the solver passes the change on to related variables and shrinks their domains too, before any values are tried. This is **constraint propagation**.
3. **Labeling** then searches for values, but over much smaller domains.

Propagation does not make NP-complete problems easy, but it prunes so much of the search tree that many practical problems become fast. It also keeps the model (the constraints) apart from the search strategy.

## CLP(FD): Constraints over Finite Domains

**CLP(FD)** works with variables whose values are integers from a finite set. SWI-Prolog provides it in `library(clpfd)`.

Ordinary arithmetic (`is/2`, `=:=/2`) needs every variable bound. CLP(FD) constraints work in any direction and accept unbound variables.

#### Core CLP(FD) Predicates
- **`in/2` and `ins/2`**: Define the domain for a single variable or a list of variables (e.g., `X in 1..9`, `Vars ins 1..9`).
- **`#=`**, **`#\=`**: Equality and inequality.
- **`#<`, `#>`, `#=<`, `#>=`**: Comparisons.
- **`#\/`**, **`#/\`**, **`#\`**: Disjunction, conjunction, and negation of constraints.
- **`all_distinct(+List)`**, **`all_different(+List)`**: All values in the list differ. `all_distinct/1` propagates more strongly.
- **`label(+List)`**, **`labeling(+Options, +List)`**: Search for values in the remaining domains.
- **`transpose(+Matrix, -Transposed)`**: Turns rows into columns, useful for grid puzzles.

## Solving Sudoku with CLP(FD)

Sudoku shows constraint propagation well. You place the digits 1 to 9 in a `9 \times 9`$ grid so that every row, column, and `3 \times 3`$ box holds each digit once.

With `library(clpfd)`, the whole model takes about 15 lines. `all_distinct/1` propagates so strongly that it solves many puzzles with little or no search.

{width: "80%"}
![Architecture diagram for the Sudoku Solver example](FIG_sudoku_solver.jpg)

Here is the file **sudoku_solver/prolog/sudoku.pl**:

```prolog
:- module(sudoku, [
    sudoku/1,
    print_board/1
]).

:- use_module(library(clpfd)).

%% sudoku(+Rows) - Solve a 9x9 Sudoku puzzle
%% Rows is a list of 9 lists, each containing 9 elements (vars or 1-9)
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

%% print_board(+Rows) - Pretty-print the board
%% Uninstantiated cells are rendered as '.', solved cells as digits.
print_board([]).
print_board([Row|Rows]) :-
    maplist(render_cell, Row, Chars),
    format("~w~n", [Chars]),
    print_board(Rows).

render_cell(Cell, '.') :- var(Cell), !.
render_cell(Cell, Cell).
```

`blocks/3` takes three rows at a time and peels off three cells from each, which gives one `3 \times 3`$ box per step. `print_board/1` prints unbound cells as `.` and solved cells as digits.

## Cryptarithmetic: SEND + MORE = MONEY

The Search Algorithms chapter solved the N-Queens problem with CLP(FD). Here is another classic: assign a different digit to each letter so that the sum is correct.

```text
    S E N D
  + M O R E
  ---------
  M O N E Y
```

Here is the file **sudoku_solver/prolog/send_more.pl**:

```prolog
%% send_more.pl - The SEND + MORE = MONEY puzzle in CLP(FD)
:- module(send_more, [
    send_more/1
]).

:- use_module(library(clpfd)).

%% send_more(-Digits)
%% Digits = [S,E,N,D,M,O,R,Y]: distinct digits, no leading zero,
%% such that SEND + MORE = MONEY.
send_more(Digits) :-
    Digits = [S,E,N,D,M,O,R,Y],
    Digits ins 0..9,
    all_different(Digits),
    S #\= 0,
    M #\= 0,
                1000*S + 100*E + 10*N + D
              + 1000*M + 100*O + 10*R + E
    #= 10000*M + 1000*O + 100*N + 10*E + Y,
    label(Digits).
```

The model has three parts: domains (`ins`), constraints (`all_different/1`, no leading zeros, and the sum), and search (`label/1`). Propagation alone, before any search, fixes three letters: `M = 1` (the carry out of a four-digit sum can only be 1), `S = 9`, and `O = 0`. `label/1` only has to search the other five.

```prolog
?- send_more([S,E,N,D,M,O,R,Y]).
S = 9, E = 5, N = 6, D = 7, M = 1, O = 0, R = 8, Y = 2.
```

`all_different/1` propagates less than `all_distinct/1`, which the Sudoku solver uses, but it is cheaper. On this small puzzle either works.

## Scheduling and Resource Allocation

Scheduling tasks with deadlines, limited resources, and ordering rules is a classic industrial problem:
- **Precedence constraints**: Task B starts after task A ends (`StartB #>= EndA`).
- **Resource constraints**: Two tasks that use the same resource cannot overlap.
- **Deadline constraints**: A task must finish by a given time.

In CLP(FD), start and end times are integer variables, and each rule is a constraint. The **job_scheduler** project schedules jobs on one machine. Here is the file **job_scheduler/prolog/scheduler.pl**:

```prolog
%% scheduler.pl - Job scheduling with temporal constraints using CLP(FD)
:- module(scheduler, [
    schedule_jobs/2,
    no_overlap/1,
    schedule_valid/1,
    makespan/2
]).

:- use_module(library(clpfd)).

%% schedule_jobs(+Jobs, -Schedule)
%% Jobs: list of job(Name, Duration, Deadline) terms. Deadline may
%% be unbound for a job with no deadline.
%% Schedule: list of scheduled(Name, Start, End) terms, in the same
%% order as Jobs, using one machine. The solver chooses the order in
%% which the jobs run. The first answer has the smallest makespan
%% (the time the last job ends). Infeasible inputs fail.
schedule_jobs(Jobs, Schedule) :-
    horizon(Jobs, Horizon),
    maplist(create_task(Horizon), Jobs, Schedule, Starts),
    maplist(deadline_constraint, Jobs, Schedule),
    no_overlap(Schedule),
    makespan(Schedule, Makespan),
    labeling([min(Makespan)], Starts).

%% horizon(+Jobs, -Horizon)
%% No job needs to start later than the total work: any feasible
%% schedule can be shifted left until it has no idle time.
horizon(Jobs, Horizon) :-
    foldl(add_duration, Jobs, 0, Horizon).

add_duration(job(_, Duration, _), Sum0, Sum) :-
    Sum is Sum0 + Duration.

create_task(Horizon, job(Name, Duration, _Deadline),
            scheduled(Name, Start, End), Start) :-
    Start in 0..Horizon,
    End #= Start + Duration.

deadline_constraint(job(_, _, Deadline), scheduled(_, _, End)) :-
    (   integer(Deadline)
    ->  End #=< Deadline
    ;   true
    ).

%% no_overlap(+Schedule)
%% Posts constraints so that no two jobs overlap: for each pair, one
%% job ends before the other starts. #\/ is a constraint
%% disjunction, so the solver decides the order by propagation and
%% search instead of by Prolog backtracking.
no_overlap([]).
no_overlap([Task|Tasks]) :-
    maplist(disjoint(Task), Tasks),
    no_overlap(Tasks).

disjoint(scheduled(_, S1, E1), scheduled(_, S2, E2)) :-
    E1 #=< S2 #\/ E2 #=< S1.

%% makespan(+Schedule, -Makespan)
%% Makespan is the largest end time in Schedule.
makespan(Schedule, Makespan) :-
    maplist(end_time, Schedule, Ends),
    max_list_fd(Ends, Makespan).

end_time(scheduled(_, _, End), End).

max_list_fd([E|Es], Max) :-
    foldl(fd_max, Es, E, Max).

fd_max(E, M0, M) :-
    M #= max(M0, E).

%% schedule_valid(+Schedule)
%% Verifies a fully ground schedule: no two jobs overlap.  Uses plain
%% numeric comparisons (no constraint posting) and fails if the
%% schedule contains variables.
schedule_valid(Schedule) :-
    maplist(ground, Schedule),
    \+ overlaps_any_pair(Schedule, Schedule).

overlaps_any_pair([S|_], All) :-
    overlaps_one(S, All).
overlaps_any_pair([_|Ss], All) :-
    overlaps_any_pair(Ss, All).

overlaps_one(S, All) :-
    member(T, All),
    S \== T,
    S = scheduled(_, StartS, EndS),
    T = scheduled(_, StartT, EndT),
    StartS < EndT,
    StartT < EndS.
```

The key constraint is in `disjoint/2`: `E1 #=< S2 #\/ E2 #=< S1` says one job ends before the other starts, without saying which. The solver picks the order. A Prolog disjunction `(A ; B)` would also work, but it would choose by backtracking, while `#\/` lets propagation rule out an order as soon as the domains show it cannot work. (`library(clpfd)` also has `serialized/2` and `cumulative/2`, which post the same kind of constraint for a whole list of tasks.)

No job need start later than the total work, so that is the horizon for the start times. `labeling([min(Makespan)], Starts)` searches for the schedule with the earliest finish time.

```prolog
?- schedule_jobs([job(a, 5, 10), job(b, 2, 2)], S).
S = [scheduled(a, 2, 7), scheduled(b, 0, 2)] .
```

Job `b` must finish by time 2, so the solver runs it first, though the list names `a` first. `no_overlap/1` posts constraints on unbound variables. To check a schedule that is already ground, use `schedule_valid/1`, which compares the numbers directly.

## CLP(R) and CLP(Q): Constraints over Reals and Rationals

CLP(FD) handles integers. SWI-Prolog also has solvers for continuous values:
- **`library(clpr)`**: Constraints over Real numbers.
- **`library(clpq)`**: Constraints over Rational numbers.

They solve systems of linear equations and inequalities, using the **simplex algorithm** for inequalities and optimization.

#### Example: Simultaneous Equations
Constraints go inside curly braces:

```prolog
?- use_module(library(clpr)).

?- {X + Y =:= 10, X - Y =:= 4}.
X = 7.0,
Y = 3.0.
```

CLP(R) suits problems with continuous quantities such as money, voltage, or distance, as in circuit analysis and financial models. CLP(Q) gives exact rational answers, with no floating-point rounding.

## CLP(B): Boolean Constraints

**CLP(B)** works with boolean variables, which take the values `0` (false) and `1` (true). It is in `library(clpb)`.

CLP(B) represents formulas as **Binary Decision Diagrams (BDDs)**. It can count solutions and check whether two formulas are equivalent, which is useful for verifying digital circuits.

#### Example: Logic Gate Satisfiability
The operators are AND `*`, OR `+`, NOT `~`, and XOR `#`:

```prolog
?- use_module(library(clpb)).

% Find values for X and Y that satisfy (X AND Y = 1)
?- sat(X * Y =:= 1).
X = 1,
Y = 1.
```

## Optional Practice Problems

1. **Machines and Precedence**: Extend `job_scheduler` so each job also names a machine, and only jobs on the same machine must not overlap. Add `before(JobA, JobB)` facts for precedence constraints.
2. **Labeling Strategies**: Time `n_queens(N, Qs)` and `n_queens(N, [ff_opt(true)], Qs)` from the Search Algorithms chapter for N = 8, 20, and 40 with `time/1`. Which strategy wins, and why?
3. **Counting with CLP(B)**: Use `sat_count/2` to count the assignments of five boolean variables in which exactly two are true.
