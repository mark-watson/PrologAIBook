# Graph Search

Depth-first search, breadth-first search, and A* heuristic search over graphs. Companion code for the Search Algorithms chapter.

## Running Examples

```shell
cd source-code/graph_search
swipl -s load.pl
```

```prolog
?- dfs(a, e, Path).
?- bfs(a, e, Path).
?- astar(a, e, 'distance_heuristic/2', Path).
```

## Running Tests

```shell
swipl -g "['tests/test_search.pl'], run_tests, halt" -s load.pl
```


## Architecture

![DFS, BFS, and A* search algorithms over a shared graph data layer](FIG_graph_search.jpg)

## Description

Implements three classic AI search algorithms over a sample directed graph. `dfs.pl` performs depth-first search with cycle detection using a visited list. `bfs.pl` uses an explicit queue to explore nodes level by level. `astar.pl` implements A* with a pluggable heuristic predicate (uses `safe_call/3` to handle missing heuristics gracefully), maintaining an open list sorted by f-cost. The graph is defined as `edge/2` facts, making it easy to swap in different problem domains.
