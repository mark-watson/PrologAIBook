# Search Algorithms in Prolog

Prolog's backtracking mechanism is, at its core, a search engine. In this chapter we build on that foundation to implement classic AI search algorithms — taking advantage of Prolog's natural representation of graphs, states, and goals.

{width: "80%"}
![Architecture diagram for the Graph Search example](FIG_graph_search.jpg)

{width: "80%"}
![Architecture diagram for the Puzzle Solver example](FIG_puzzle_solver.jpg)

{width: "80%"}
![Architecture diagram for the N-Queens example](FIG_n_queens.jpg)

## Depth-First and Breadth-First Search

TBD: Implementing DFS and BFS over graphs in Prolog. Cycle detection. Comparing Prolog's built-in backtracking (which is DFS) with an explicit BFS using a queue.

The **graph_search** project implements both algorithms. Here is the file **graph_search/prolog/dfs.pl**:

```prolog
%% dfs.pl - Depth-first search with cycle detection
:- module(dfs, [dfs/3]).

%% dfs(+Start, +Goal, -Path)
dfs(Start, Goal, Path) :-
    dfs_helper(Start, Goal, [Start], RevPath),
    reverse(RevPath, Path).

dfs_helper(Goal, Goal, Visited, Visited).
dfs_helper(Current, Goal, Visited, Path) :-
    edge(Current, Next),
    \+ member(Next, Visited),
    dfs_helper(Next, Goal, [Next|Visited], Path).
```

And the breadth-first search using an explicit queue. Here is the file **graph_search/prolog/bfs.pl**:

```prolog
%% bfs.pl - Breadth-first search using a queue
:- module(bfs, [bfs/3]).

%% bfs(+Start, +Goal, -Path)
bfs(Start, Goal, Path) :-
    bfs_queue([[Start]], Goal, RevPath),
    reverse(RevPath, Path).

bfs_queue([[Goal|Visited]|_], Goal, [Goal|Visited]).
bfs_queue([[Current|Visited]|Rest], Goal, Path) :-
    findall(
        [Next, Current|Visited],
        (edge(Current, Next), \+ member(Next, [Current|Visited])),
        NewPaths
    ),
    append(Rest, NewPaths, Queue),
    bfs_queue(Queue, Goal, Path).
```

## Iterative Deepening

TBD: Combining the space efficiency of DFS with the completeness of BFS. SWI-Prolog's built-in support.

## A* Heuristic Search

TBD: Implementing A* search in Prolog using priority queues. Defining heuristic functions as Prolog predicates. Comparison with the Common Lisp A* implementation from the author's other books.

## State-Space Search and Puzzle Solving

TBD: Modeling classic puzzles (e.g., the farmer-fox-chicken-grain problem, 8-puzzle) as state-space search problems in Prolog. Using Prolog's unification to match goal states.

The **puzzle_solver** project implements the classic farmer-fox-chicken-grain river crossing puzzle. Here is the file **puzzle_solver/prolog/farmer.pl**:

```prolog
%% farmer.pl - Farmer, Fox, Chicken, Grain river crossing puzzle
:- module(farmer, [solve_farmer/1]).

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

%% Safety: fox cannot be alone with chicken,
%% chicken cannot be alone with grain
safe(state(Farmer, Fox, Chicken, Grain)) :-
    (Fox == Chicken -> Farmer == Fox ; true),
    (Chicken == Grain -> Farmer == Chicken ; true).
```

## Search with Tabling (Memoization)

TBD: Using SWI-Prolog's tabling (`:- table predicate/arity.`) to memoize search results, avoid infinite loops in graph search, and dramatically improve performance on dynamic programming problems.
