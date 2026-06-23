# Constraint Logic Programming

Constraint Logic Programming (CLP) extends Prolog with the ability to reason about constraints over various domains — integers, reals, and finite domains. SWI-Prolog provides excellent CLP libraries that make it possible to solve complex combinatorial and optimization problems declaratively.

## Introduction to CLP

In traditional logic programming, evaluation relies on unification and backtracking. For complex search problems, this often leads to a **generate-and-test** strategy: the program instantiates variables to concrete values and then checks if they satisfy the problem conditions. If they do not, it backtracks and tries other values. For large combinatorial search spaces, this approach is extremely inefficient.

**Constraint Logic Programming (CLP)** replaces this with a **constrain-and-generate** paradigm:
1. **Constraints** are declarative relations that restrict the set of possible values (domains) that variables can take.
2. The **Constraint Solver** maintains these relations. As soon as a variable's domain is reduced, the solver automatically propagates this restriction to other related variables, narrowing their domains before concrete values are ever assigned. This process is called **constraint propagation**.
3. By pruning branches of the search tree early, CLP turns NP-complete search problems into highly efficient deterministic operations, separating the description of the constraints from the search logic.

## CLP(FD): Constraints over Finite Domains

Finite Domain constraint solving, or **CLP(FD)**, deals with variables whose values are restricted to discrete, finite sets of integers. In SWI-Prolog, this is implemented in `library(clpfd)`.

Unlike ordinary arithmetic operators (like `is/2` or `=:=/2`), which require all variables to be fully bound to values, CLP(FD) relations are bidirectional and can evaluate partially instantiated variables.

#### Core CLP(FD) Predicates
- **`in/2` and `ins/2`**: Define the domain for a single variable or a list of variables (e.g., `X in 1..9`, `Vars ins 1..9`).
- **`#=`**: Constraint equality.
- **`#\=`**: Constraint inequality.
- **`#<`, `#>`, `#=<`, `#>=`**: Constraint arithmetic comparisons.
- **`all_distinct(+List)`**: A high-performance constraint asserting that all integers in the list must be unique.
- **`label(+List)`**: Triggers backtracking search to instantiate variables to concrete values from their remaining domains.
- **`transpose(+Matrix, -Transposed)`**: Transposes a 2D list matrix, crucial for grid-based constraints (such as column checks).

## Solving Sudoku with CLP(FD)

A classic demonstration of constraint propagation is solving Sudoku puzzles. Standard Sudoku requires placing digits 1 to 9 in a `9 \times 9`$ grid such that every row, column, and `3 \times 3`$ sub-grid block contains unique numbers.

Using `library(clpfd)`, we can model this complete constraint system in under 20 lines of logic. The solver propagates constraints so efficiently that most puzzles are solved instantly without any backtracking search at all.

{width: "80%"}
![Architecture diagram for the Sudoku Solver example](FIG_sudoku_solver.jpg)

The **sudoku_solver** project provides a complete solver in under 30 lines of logic. Here is the file **sudoku_solver/prolog/sudoku.pl**:

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

%% print_board(+Rows) - Pretty-print a solved board
print_board([]).
print_board([Row|Rows]) :-
    format("~w~n", [Row]),
    print_board(Rows).
```

## The N-Queens Problem

The N-Queens problem asks how to place `N`$ non-attacking queens on an `N \times N`$ chessboard.
- **Naive Backtracking**: Places a queen row-by-row, recursively checking for row, column, and diagonal conflicts. If a conflict is found, it backtracks. This checks many invalid states.
- **CLP(FD) Search**: Declares queen positions as variables, constrains their columns and diagonals, and uses constraint propagation to prune invalid domains before values are labeled. This limits backtracking.

The diagonal constraints are written using arithmetic offsets: two queens at columns `Q`$ and `Q_1`$ separated by `D`$ rows are on the same diagonal if `|Q - Q_1| = D`$, which translates to `Q #\= Q1 + D` and `Q #\= Q1 - D`.

The **n_queens** project solves the problem using CLP(FD) diagonal constraints. Here is the file **n_queens/prolog/queens.pl**:

```prolog
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
```

## Scheduling and Resource Allocation

Scheduling tasks with deadlines, resource limitations, and ordering constraints is a classic industrial optimization problem.
- **Precedence constraints**: Task B must start after Task A ends (`StartB #>= EndA`).
- **Resource constraints**: Two tasks using the same resource cannot overlap in time.
- **Deadline constraints**: Tasks must complete before a specific time limit.

CLP(FD) lets you express these temporal equations naturally, solving complex scheduling problems by treating start and end times as integer variables.

The **job_scheduler** project models scheduling with temporal constraints. Here is the file **job_scheduler/prolog/scheduler.pl**:

```prolog
%% scheduler.pl - Job scheduling with temporal constraints using CLP(FD)
:- module(scheduler, [
    schedule_jobs/2,
    no_overlap/1
]).

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

create_task(job(Name, Duration, _Deadline), scheduled(Name, Start, End),
    Start) :-
    Start in 0..100,
    End #= Start + Duration.

deadline_constraint(job(Name, _Duration, Deadline), scheduled(Name,
    _Start, End)) :-
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

While CLP(FD) is designed for discrete integers, SWI-Prolog also provides constraint solvers over continuous domains:
- **`library(clpr)`**: Constraints over Real numbers.
- **`library(clpq)`**: Constraints over Rational numbers.

These libraries use the **Simplex algorithm** under the hood to solve systems of linear equations and inequalities, propagating constraints across real-valued variables.

#### Example: Simultaneous Equations
We can express continuous equations using curly brace `{ ... }` syntax:

```prolog
?- use_module(library(clpr)).

?- {X + Y =:= 10, X - Y =:= 4}.
X = 7.0,
Y = 3.0.
```

CLP(R) is widely used in engineering (e.g., electrical circuit analysis), financial modeling, and optimization where variables represent continuous values like currency, voltage, or distance.

## CLP(B): Boolean Constraints

Boolean constraint solving, or **CLP(B)**, operates on boolean variables (restricted to the values `0` for false and `1` for true). It is implemented in `library(clpb)`.

CLP(B) uses **Binary Decision Diagrams (BDDs)** to represent and solve boolean formulas efficiently, making it powerful for Boolean Satisfiability (SAT) solving, combinatorial verification, and digital circuit design.

#### Example: Logic Gate Satisfiability
We can express logical operations (such as AND `*`, OR `+`, NOT `~`, XOR `#`) and verify conditions:

```prolog
?- use_module(library(clpb)).

% Find values for X and Y that satisfy (X AND Y = 1)
?- sat(X * Y =:= 1).
X = 1,
Y = 1.
```

## Optional Practice Problems

1. **Cryptarithmetic Solver**: In the `sudoku_solver` or `n_queens` project directories, create a new file that solves the classic cryptarithmetic puzzle `SEND + MORE = MONEY` using CLP(FD) constraints.
2. **Variable Board Size**: Modify the N-Queens solver in `n_queens` to run dynamically for any board size `N` supplied at the query prompt, profiling the performance differences between smaller and larger boards.
