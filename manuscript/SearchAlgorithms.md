# Search Algorithms in Prolog

Prolog's backtracking mechanism is, at its core, a search engine. In this chapter we build on that foundation to implement classic AI search algorithms — taking advantage of Prolog's natural representation of graphs, states, and goals.

## Loading Graph Data from a File

Rather than hard-coding edges inside the search modules, we keep the graph in a separate data file, **graph_search/sample_graph.txt**, using standard Prolog term syntax:

```prolog
edge(albany,  boston).
edge(albany,  chicago).
edge(albany,  detroit).
edge(boston,   chicago).
edge(boston,   eton).
edge(chicago,  detroit).
edge(chicago,  fresno).
%% ... 30 more edges spanning 20 cities ...
edge(portland, reno).
edge(quincy,   reno).
```

The utility module **graph_search/prolog/read_graph.pl** reads this file and asserts each edge as a dynamic fact:

```prolog
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
```


{width: "80%"}
![Architecture diagram for the Graph Search example](FIG_graph_search.jpg)

This design makes it easy to swap in different graphs without touching the search algorithms.

## Depth-First and Breadth-First Search

With the graph loaded dynamically, the search modules simply import `edge/2` from `read_graph`. Depth-first search explores as deep as possible along each branch before backtracking, using a visited list for cycle detection. Here is **graph_search/prolog/dfs.pl**:

```prolog
:- use_module(read_graph, [edge/2]).

%% dfs(+Start, +Goal, -Path)
dfs(Start, Goal, Path) :-
    dfs(Start, Goal, [Start], Path).

dfs(Goal, Goal, Visited, Path) :-
    reverse(Visited, Path).
dfs(Current, Goal, Visited, Path) :-
    edge(Current, Next),
    \+ member(Next, Visited),
    dfs(Next, Goal, [Next|Visited], Path).
```

Breadth-first search instead explores all neighbors at the current depth before moving deeper, using an explicit queue of partial paths. Here is **graph_search/prolog/bfs.pl**:

```prolog
:- use_module(read_graph, [edge/2]).

%% bfs(+Start, +Goal, -Path)
bfs(Start, Goal, Path) :-
    bfs_queue([[Start]], Goal, Path).

bfs_queue([[Goal|Visited]|_], Goal, Path) :-
    reverse([Goal|Visited], Path).
bfs_queue([[Current|Visited]|Rest], Goal, Path) :-
    findall(
        [Next, Current|Visited],
        (edge(Current, Next), \+ member(Next, [Current|Visited])),
        Children
    ),
    append(Rest, Children, NewQueue),
    bfs_queue(NewQueue, Goal, Path).
```


{width: "80%"}
![Sample directed graph used in search examples — 20 city nodes from Albany (start) to Reno (goal)](graph_search_sample.jpg)


Running these on our 20-node city graph:

```prolog
?- dfs(albany, reno, Path).
Path = [albany, boston, chicago, detroit, gary, houston, irving, ...]

?- bfs(albany, reno, Path).
Path = [albany, boston, eton, kent, naples, portland, reno]
```

Notice that BFS finds the shortest path (7 nodes), while DFS may explore a longer route through the interior of the graph.

## Iterative Deepening

TBD: Combining the space efficiency of DFS with the completeness of BFS. SWI-Prolog's built-in support.

## A* Heuristic Search

A* combines the actual path cost with a heuristic estimate of the remaining distance to the goal. By maintaining an open list sorted by f-cost (g + h), it explores the most promising paths first. Here is **graph_search/prolog/astar.pl**:

```prolog
:- module(astar, [
    astar/4,
    distance_heuristic/2,
    zero_heuristic/2
]).

:- use_module(read_graph, [edge/2]).

%% Safe call: if Heuristic(Node, Value) fails with existence error,
%% return 0.
safe_call(Callable, Node, Value) :-
    catch(call(Callable, Node, Value), _, Value = 0).

%% A* search: accepts both string designators ('h/2') and callable terms
%% (?(-N,-V)).
astar(Start, Goal, Heuristic, Path) :-
    safe_call(Heuristic, Start, H0),
    H is H0 + 0,
    astar_loop([node(H, 0, [Start])], Goal, Heuristic, Path).

astar_loop([node(_, _, [Goal|Rest])|_], Goal, _, Path) :-
    reverse([Goal|Rest], Path).
astar_loop([node(_, G, [Current|Rest])|Open], Goal, Heuristic, Path) :-
    findall(
        node(F1, G1, [Next, Current|Rest]),
            (   edge(Current, Next),
                \+ member(Next, [Current|Rest]),
            G1 is G + 1,
            safe_call(Heuristic, Next, H0),
            H is H0 + 0,
            F1 is G1 + H
            ),
        Children
       ),
    append(Open, Children, Unsorted),
    sort(1, @=<, Unsorted, Sorted),
    astar_loop(Sorted, Goal, Heuristic, Path).

%% Zero heuristic: admissible for uniform-weight graphs (all edge
%% weights = 1).
%% Useful as a baseline for testing A* correctness.
zero_heuristic(_, 0).

%% Example heuristic: estimated remaining distance to goal (reno).
%% Rough estimates for the sample_graph cities — admissible for
%% uniform-weight graph.
distance_heuristic(reno,      0).
distance_heuristic(portland,  1).
distance_heuristic(quincy,    1).
distance_heuristic(omaha,     2).
distance_heuristic(naples,    2).
distance_heuristic(memphis,   3).
distance_heuristic(lansing,   3).
distance_heuristic(kent,      3).
distance_heuristic(jackson,   4).
distance_heuristic(irving,    4).
distance_heuristic(houston,   4).
distance_heuristic(gary,      5).
distance_heuristic(fresno,    5).
distance_heuristic(eton,      5).
distance_heuristic(detroit,   5).
distance_heuristic(chicago,   6).
distance_heuristic(boston,     6).
distance_heuristic(albany,    7).
```

```prolog
?- astar(albany, reno, distance_heuristic, Path).
Path = [albany, boston, eton, kent, naples, portland, reno]
```

The heuristic guides A* directly toward the goal, avoiding the unnecessary exploration of interior nodes that DFS would visit.

## State-Space Search and Puzzle Solving

TBD: Modeling classic puzzles (e.g., the farmer-fox-chicken-grain problem, 8-puzzle) as state-space search problems in Prolog. Using Prolog's unification to match goal states.


{width: "80%"}
![Architecture diagram for the Puzzle Solver example](FIG_puzzle_solver.jpg)


The **puzzle_solver** project implements the classic farmer-fox-chicken-grain river crossing puzzle. Here is the file **puzzle_solver/prolog/farmer.pl**:

```prolog
    solve_farmer/1
]).

%% State: state(Farmer, Fox, Chicken, Grain) where each is 'left' or
%% 'right'
%% Goal: all on the right bank

solve_farmer(Moves) :-
    InitState = state(left, left, left, left),
    GoalState = state(right, right, right, right),
    solve(InitState, GoalState, [InitState], RevMoves),
    reverse(RevMoves, Moves).

solve(Goal, Goal, _Visited, []).
solve(State, Goal, Visited, [Description|Moves]) :-
    move(State, NextState, Description),
    safe(NextState),
    \+ member(NextState, Visited),
    solve(NextState, Goal, [NextState|Visited], Moves).

%% Moves: farmer always crosses, optionally carrying one item
move(state(left,F,C,G), state(right,F,C,G), farmer_alone).
move(state(right,F,C,G), state(left,F,C,G), farmer_alone).
move(state(left,left,C,G), state(right,right,C,G), farmer_fox).
move(state(right,right,C,G), state(left,left,C,G), farmer_fox).
move(state(left,F,left,G), state(right,F,right,G), farmer_chicken).
move(state(right,F,right,G), state(left,F,left,G), farmer_chicken).
move(state(left,F,C,left), state(right,F,C,right), farmer_grain).
move(state(right,F,C,right), state(left,F,C,left), farmer_grain).

%% Safety: fox cannot be alone with chicken, chicken cannot be alone
%% with grain
safe(state(Farmer, Fox, Chicken, Grain)) :-
    (Fox == Chicken -> Farmer == Fox ; true),
    (Chicken == Grain -> Farmer == Chicken ; true).
```


## Constraint-Based Search: The N-Queens Problem

A third powerful paradigm for search in Prolog is **Constraint Logic Programming**, specifically Constraint Logic Programming over Finite Domains (`CLP(FD)`). Instead of manually coding depth-first search or backtracking state transitions, you define variables, their domains, and the relationships (constraints) that must hold true. Prolog's constraint solver then automatically propagates these constraints to prune the search space and find valid assignments.

To illustrate this, we can look at the classic **N-Queens problem**, which asks how to place $N$ queens on an $N \times N$ chessboard such that no two queens can attack each other. This means no two queens can share the same row, column, or diagonal.

{width: "80%"}
![Architecture diagram for the N-Queens example](FIG_n_queens.jpg)

The companion project **n_queens** implements this solver. Here is the complete file **n_queens/prolog/queens.pl**:

```prolog
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

### How the CLP(FD) Search Works

1. **Representation**: We represent the board as a list of length $N$ called `Queens`. The index of an element in the list represents the row number (1 to $N$), and the value at that index represents the column number of the queen in that row.
2. **Domain**: `Queens ins 1..N` establishes that each variable in the `Queens` list must be an integer between $1$ and $N$.
3. **Column Constraints**: Since each row has exactly one queen, we only need to ensure no two queens share a column. By using the list representation, the index ensures row uniqueness. The column constraint `Q #\= Q1` (in `safe_queen/3`) ensures that no two queens share the same column.
4. **Diagonal Constraints**: Two queens at columns $Q$ and $Q_1$ separated by $D$ rows are on the same diagonal if $|Q - Q_1| = D$. This is elegantly modeled using two inequality constraints:
   - `Q #\= Q1 + D` (upper-diagonal check)
   - `Q #\= Q1 - D` (lower-diagonal check)
5. **Labeling**: `label(Queens)` tells the constraint solver to perform the backtracking search to assign concrete values to the variables in the `Queens` list that satisfy all constraints.

### Running the Solver

You can run queries in the REPL to solve for a specific size $N$:

```prolog
?- n_queens(8, Queens).
Queens = [1, 5, 8, 6, 3, 7, 2, 4] .
```

To count the total number of solutions for an 8x8 board:

```prolog
?- aggregate_all(count, n_queens(8, _), Count).
Count = 92.
```

CLP(FD) propagation dramatically prunes the search space relative to a naive backtracking search, making the search for solutions extremely efficient even for larger board sizes.
