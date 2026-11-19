# Search Algorithms in Prolog

Prolog's backtracking is a built-in search engine. In this chapter we use it to write classic AI search algorithms over graphs and state spaces.

## Loading Graph Data from a File

We keep the graph out of the search modules, in the data file **graph_search/sample_graph.txt**, written as Prolog terms:

```prolog
edge(albany,  boston).
edge(albany,  chicago).
edge(albany,  detroit).
edge(boston,   chicago).
edge(boston,   eton).
edge(chicago,  detroit).
edge(chicago,  fresno).
%% ... 28 more edges, 37 in all, linking 18 cities ...
edge(quincy,   reno).
edge(portland, reno).
```

The module **graph_search/prolog/read_graph.pl** reads this file and asserts each edge as a dynamic fact:

```prolog
:- module(read_graph, [
    load_graph/0,
    load_graph/1,
    clear_graph/0,
    edge/2
]).

:- dynamic edge/2.

%% clear_graph/0 - Remove all loaded edge/2 facts.
clear_graph :-
    retractall(edge(_, _)).

%% load_graph/0 - Load graph from default file (sample_graph.txt
%% located next to this pack's prolog/ directory).
load_graph :-
    source_file(read_graph:edge(_, _), SrcFile),
    file_directory_name(SrcFile, PrologDir),
    file_directory_name(PrologDir, ProjectDir),
    atomic_list_concat([ProjectDir, '/sample_graph.txt'], DefaultFile),
    load_graph(DefaultFile).

%% load_graph/1 - Load graph from a specified file
%%   Reads lines of the form:  edge(Source, Destination).
%%   Clears any previously loaded edges first.  Malformed terms
%%   are counted and reported as a warning when reading finishes.
load_graph(File) :-
    clear_graph,
    setup_call_cleanup(
        open(File, read, Stream),
        read_edges(Stream, 0, Skipped),
        close(Stream)
    ),
    (   Skipped > 0
    ->  print_message(warning, read_graph_skipped(Skipped))
    ;   true
    ).

read_edges(Stream, Skip0, Skip) :-
    read_term(Stream, Term, []),
    (   Term == end_of_file
    ->  Skip = Skip0
    ;   (   Term = edge(From, To)
        ->  assertz(edge(From, To)),
            Skip1 = Skip0
        ;   Skip1 is Skip0 + 1
        ),
        read_edges(Stream, Skip1, Skip)
    ).
```

`clear_graph/0` removes all loaded `edge/2` facts. `load_graph/1` calls it first, then warns if it skipped any terms that are not `edge/2` facts. `load_graph/0` finds **sample_graph.txt** relative to the source file, so it works from any directory.


{width: "80%"}
![Architecture diagram for the Graph Search example](FIG_graph_search.jpg)

You can load a different graph without changing the search code.

## Depth-First and Breadth-First Search

The search modules import `edge/2` from `read_graph`. Depth-first search follows each branch as deep as it can before backtracking, and keeps a visited list to avoid cycles. Here is **graph_search/prolog/dfs.pl**:

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

Breadth-first search visits every node at the current depth before going deeper. It keeps a queue of partial paths, each stored in reverse with the newest node first. Here is **graph_search/prolog/bfs.pl**:

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
![Sample directed graph used in search examples, 18 city nodes from Albany (start) to Reno (goal)](graph_search_sample.jpg)


Running these on our 18-node city graph (from the `graph_search` directory, start `swipl load.pl`):

```prolog
?- dfs(albany, reno, Path).
Path = [albany, boston, chicago, detroit, gary, houston, irving,
        jackson, kent, memphis, naples, omaha, portland, quincy, reno]

?- bfs(albany, reno, Path).
Path = [albany, boston, eton, kent, naples, portland, reno]
```

BFS finds a shortest path (7 nodes, 6 edges). DFS returns the first path it finds, which here visits 15 of the 18 cities.

## Iterative Deepening

DFS needs little memory: it stores only the current path, so its memory use grows with the search depth, `O(d)`$. But DFS is not complete on infinite graphs and need not find a shortest path, as we saw above. BFS is complete and finds a shortest path, but it must store every partial path in its queue, so its memory use grows as `O(b^d)`$, where `b`$ is the branching factor.

**Iterative Deepening Search (IDS)** combines the low memory use of DFS with the completeness of BFS, and on graphs where every edge costs the same, it also finds a shortest path.

IDS runs a depth-limited DFS with limit 1, then 2, and so on. Searching the top of the tree again on each pass looks wasteful, but most nodes sit at the deepest level, so the extra work is small. With branching factor `b`$, IDS does about `b/(b-1)`$ times the work of one search to the final depth: about 11% extra for `b = 10`$, and about twice the work for a binary tree.

### Custom Pure Prolog Implementation

In Prolog, IDS takes a few lines. The built-in `between/3` generates depth limits from 1 upward, and a depth-limited DFS does the search. Here is the first part of **graph_search/prolog/ids.pl**:

```prolog
%% ids(+Start, +Goal, -Path)
%% Iterative Deepening Search: raises the depth limit by one on
%% each pass, so the first path found is a shortest one.
ids(Start, Goal, Path) :-
    between(1, 100, DepthLimit),
    depth_limited_dfs(Start, Goal, [Start], DepthLimit, Path),
    !.

%% depth_limited_dfs(+Current, +Goal, +Visited, +Limit, -Path)
depth_limited_dfs(Goal, Goal, Visited, _, Path) :-
    !,
    reverse(Visited, Path).
depth_limited_dfs(Current, Goal, Visited, Limit, Path) :-
    Limit > 0,
    edge(Current, Next),
    \+ member(Next, Visited),
    NextLimit is Limit - 1,
    depth_limited_dfs(Next, Goal, [Next|Visited], NextLimit, Path).
```

If `depth_limited_dfs/5` fails to reach the goal within `DepthLimit`, Prolog backtracks into `between/3`, which yields the next limit, and the search starts again. Like BFS, the first path found is a shortest one. The cut after the search stops `ids/3` from returning longer paths on backtracking. If no path exists, `ids/3` fails only after trying all 100 limits.

### Built-in Support: `call_with_depth_limit/3`

SWI-Prolog has a built-in meta-predicate, `call_with_depth_limit(:Goal, +Limit, -Result)`, that limits the recursion depth of any goal.

If the goal succeeds within the limit, `Result` is the deepest level reached. If the goal hit the limit, `Result` is the atom `depth_limit_exceeded`. We can wrap our unbounded `dfs/3` with it. This is the rest of **ids.pl**:

```prolog
%% ids_builtin(+Start, +Goal, -Path)
%% The same idea using call_with_depth_limit/3 around dfs/3. The
%% limit counts Prolog call depth, not graph edges.
ids_builtin(Start, Goal, Path) :-
    between(1, 100, Limit),
    call_with_depth_limit(dfs(Start, Goal, Path), Limit, Result),
    Result \== depth_limit_exceeded,
    !.
```

The built-in version is handy for putting a depth limit on existing code, such as a set of reasoning rules. Its limit counts Prolog calls, though, not graph edges, so the first path it returns is short but need not be the shortest. When you need exact control, write a depth-limited search such as `depth_limited_dfs/5`.

```prolog
?- ids(albany, reno, Path).
Path = [albany, boston, eton, kent, naples, portland, reno].
```

## A* Heuristic Search

A* adds the cost of the path so far, *g*, to a heuristic estimate of the cost to reach the goal, *h*. It keeps an open list sorted by *f = g + h* and always expands the path with the lowest *f*. If the heuristic never overestimates the true cost (it is *admissible*), the first path A* returns is a shortest one. Here is **graph_search/prolog/astar.pl**:

```prolog
:- module(astar, [
    astar/4,
    distance_heuristic/2,
    zero_heuristic/2
]).

:- use_module(read_graph, [edge/2]).

%% A* search with a closed list of best-known g values.
%% A popped entry whose g is no better than the closed g for its
%% node is stale and skipped. Any other entry is expanded, which
%% re-opens a closed node when a cheaper path reaches it (needed
%% when the heuristic is admissible but not consistent).
%% Heuristic may be any callable term.
astar(Start, Goal, Heuristic, Path) :-
    safe_call(Heuristic, Start, H0),
    astar_loop([node(H0, 0, [Start])], Goal, Heuristic, [], Path).

astar_loop([node(_, _, [Goal|Rest])|_], Goal, _, _Closed, Path) :-
    !,
    reverse([Goal|Rest], Path).
astar_loop([node(_, G, [Current|_])|Open], Goal, Heuristic, Closed, Path) :-
    best_g(Current, Closed, GBest),
    G >= GBest,
    !,                               % stale entry: skip it
    astar_loop(Open, Goal, Heuristic, Closed, Path).
astar_loop([node(_, G, [Current|Rest])|Open], Goal, Heuristic, Closed, Path) :-
    findall(
        node(F1, G1, [Next, Current|Rest]),
        (   edge(Current, Next),
            \+ member(Next, [Current|Rest]),
            G1 is G + 1,
            safe_call(Heuristic, Next, H),
            F1 is G1 + H
        ),
        Children
    ),
    append(Open, Children, Unsorted),
    sort(1, @=<, Unsorted, Sorted),
    astar_loop(Sorted, Goal, Heuristic, [best_g(Current, G)|Closed], Path).

%% best_g(+Node, +Closed, -G): G is the best g recorded for Node.
%% The newest entry comes first, so it is the cheapest one.
best_g(Node, [best_g(Node, G)|_], G) :- !.
best_g(Node, [_|Closed], G) :- best_g(Node, Closed, G).

%% Safe call: evaluate Heuristic(Node, Value).  Only an undefined
%% heuristic predicate (existence error) falls back to 0; any
%% other exception propagates to the caller.
safe_call(Callable, Node, Value) :-
    catch(call(Callable, Node, Value),
          error(existence_error(_, _), _),
          Value = 0).

%% Zero heuristic: admissible for uniform-weight graphs (all edge
%% weights = 1).
%% Useful as a baseline for testing A* correctness.
zero_heuristic(_, 0).

%% Example heuristic: estimated number of edges left to reach reno.
%% Each value is at most the true shortest distance, so the
%% heuristic is admissible and A* returns a shortest path.
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
distance_heuristic(eton,      4).
distance_heuristic(detroit,   5).
distance_heuristic(chicago,   6).
distance_heuristic(boston,    5).
distance_heuristic(albany,    6).
```

```prolog
?- astar(albany, reno, distance_heuristic, Path).
Path = [albany, boston, eton, kent, naples, portland, reno].
```

The path has six edges, the same as the BFS path. The heuristic steers A* toward the goal, so it expands fewer nodes than BFS.

The closed list stores the best *g* found for each expanded node. When A* pops an entry for a closed node, it skips the entry unless the new *g* is lower. A lower *g* means A* found a cheaper path to a node it already expanded, which can happen when a heuristic is admissible but not *consistent* (a heuristic is consistent if `h(n)` never exceeds the cost of an edge from `n` to `m` plus `h(m)`). In that case the code expands the node again. The test `astar_reopens_closed_node` in **tests/test_search.pl** builds a small graph that needs this step.

The unit tests also check that `distance_heuristic/2` is admissible: for every city, the estimate must not exceed the BFS distance to `reno`.

## State-Space Search and Puzzle Solving

Many classic AI problems fit **state-space search**. We define:
1. **State representation**: A term that describes the world at one moment.
2. **Initial state**: The starting configuration.
3. **Goal state**: The target configuration we want to reach.
4. **State transitions (moves)**: Legal actions that change one state into another.
5. **Constraints**: Conditions a state must meet to be valid or safe.

Backtracking and pattern matching make Prolog a good fit. A DFS can walk the states for us, and unification tests whether a state matches the goal.

### The Farmer, Fox, Chicken, and Grain Puzzle

As an example we solve the classic river crossing puzzle: a farmer must take a fox, a chicken, and a sack of grain from the left bank of a river to the right bank. The constraints are:
- The boat holds the farmer and at most one other item.
- If the farmer leaves the fox and chicken alone on a bank, the fox eats the chicken.
- If the farmer leaves the chicken and grain alone on a bank, the chicken eats the grain.

We represent a state as `state(Farmer, Fox, Chicken, Grain)`, where each argument is `left` or `right`, the bank that item is on.

Here is the complete file **puzzle_solver/prolog/farmer.pl**:

```prolog
%% farmer.pl - Farmer, Fox, Chicken, Grain river crossing puzzle
%% Demonstrates state-space search with Prolog backtracking
:- module(farmer, [
    solve_farmer/1
]).

%% State: state(Farmer, Fox, Chicken, Grain) where each is 'left' or
%% 'right'
%% Goal: all on the right bank

solve_farmer(Moves) :-
    InitState = state(left, left, left, left),
    GoalState = state(right, right, right, right),
    solve(InitState, GoalState, [InitState], Moves).

%% solve(+State, +Goal, +Visited, -Moves)
%% Depth-first search. Moves comes back in the order the farmer
%% makes them, since each move is added in front of the moves
%% that follow it.
solve(Goal, Goal, _Visited, []).
solve(State, Goal, Visited, [Description|Moves]) :-
    move(State, NextState, Description),
    safe(NextState),
    \+ member(NextState, Visited),
    solve(NextState, Goal, [NextState|Visited], Moves).

%% Moves: farmer always crosses, optionally carrying one item.
%% Each move is expressed once; opposite/2 supplies the two
%% directions, so only 4 rules are needed instead of 8.
move(state(From,F,C,G), state(To,F,C,G), farmer_alone) :-
    opposite(From, To).
move(state(From,From,C,G), state(To,To,C,G), farmer_fox) :-
    opposite(From, To).
move(state(From,F,From,G), state(To,F,To,G), farmer_chicken) :-
    opposite(From, To).
move(state(From,F,C,From), state(To,F,C,To), farmer_grain) :-
    opposite(From, To).

%% opposite(+Bank, -OtherBank): the two river banks.
opposite(left, right).
opposite(right, left).

%% Safety: a state is unsafe when the fox and chicken (or chicken
%% and grain) share a bank while the farmer is on the opposite
%% bank. Uses only head pattern matching through opposite/2.
safe(State) :-
    \+ unsafe(State).

unsafe(state(Farmer, Bank, Bank, _)) :-
    opposite(Farmer, Bank).             % fox left with chicken
unsafe(state(Farmer, _, Bank, Bank)) :-
    opposite(Farmer, Bank).             % chicken left with grain
```

The `move/3` clauses use repeated variables in the head to test where things are. In `move(state(From,From,C,G), ...)`, the farmer and the fox must be on the same bank, `From`, for the farmer to take the fox. `solve/4` adds each move to the front of the list of moves that follow it, so `Moves` comes out in the order the farmer makes them:

```prolog
?- solve_farmer(Moves).
Moves = [farmer_chicken, farmer_alone, farmer_fox, farmer_chicken,
         farmer_grain, farmer_alone, farmer_chicken] .
```

The farmer takes the chicken across, returns alone, takes the fox, brings the chicken back, takes the grain, returns alone, and finally takes the chicken.

## Constraint-Based Search: The N-Queens Problem

A third way to search in Prolog is **Constraint Logic Programming** over finite domains (`CLP(FD)`). Instead of coding the search yourself, you declare variables, their domains, and the constraints between them. The constraint solver uses the constraints to prune the search space as it assigns values.

As an example, the **N-Queens problem** asks how to place `N`$ queens on an `N \times N`$ chessboard so that no two queens attack each other: no two may share a row, column, or diagonal.

{width: "80%"}
![Architecture diagram for the N-Queens example](FIG_n_queens.jpg)

Here is the complete file **n_queens/prolog/queens.pl**:

```prolog
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
```

`n_queens/3` takes an options list. `ff_opt(true)` selects the first-fail labeling strategy, `labeling([ff], Queens)`, which assigns the variable with the fewest values left first. It is much faster for large `N`.

### How the CLP(FD) Search Works

1. **Representation**: The board is a list `Queens` of length `N`$. The position in the list is the row (1 to `N`$), and the value is the column of the queen in that row.
2. **Domain**: `Queens ins 1..N` makes each variable an integer from `1`$ to `N`$.
3. **Column constraints**: The list holds one queen per row, so rows never clash. The constraint `Q #\= Q1` in `safe_queen/3` keeps two queens out of the same column.
4. **Diagonal constraints**: Two queens at columns `Q`$ and `Q_1`$, `D`$ rows apart, share a diagonal if `|Q - Q_1| = D`$. Two constraints rule this out:
   - `Q #\= Q1 + D` (upper-diagonal check)
   - `Q #\= Q1 - D` (lower-diagonal check)
5. **Labeling**: `label(Queens)` starts the backtracking search that assigns a value to each variable while keeping every constraint true.

### Running the Solver

To solve for a given `N`$:

```prolog
?- n_queens(8, Queens).
Queens = [1, 5, 8, 6, 3, 7, 2, 4] .
```

To count the total number of solutions for an 8x8 board:

```prolog
?- aggregate_all(count, n_queens(8, _), Count).
Count = 92.
```

CLP(FD) propagation prunes far more of the search space than plain backtracking, and first-fail labeling keeps larger boards fast. The Constraint Logic Programming chapter covers CLP(FD) in more depth.

## Optional Practice Problems

1. **Weighted Graph Search**: In the `graph_search` project, change the graph file to hold weighted edges such as `edge(albany, boston, 3).` Then change `astar/4` to add edge weights to *g* instead of 1. With `zero_heuristic` it becomes uniform-cost search (Dijkstra's algorithm).
2. **Farmer Puzzle Variation**: In the `puzzle_solver` project, let the boat hold the farmer and up to *two* items, keeping the rules that the fox and chicken, or the chicken and grain, may not be left alone. How many crossings does the shortest solution need? (Use IDS from this chapter to find it.)
3. **Count Expanded Nodes**: Add a counter to `astar/4` and `bfs/3` that records how many nodes each expands on the albany to reno search. Compare `distance_heuristic` with `zero_heuristic`.
