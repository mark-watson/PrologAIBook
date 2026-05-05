# Blocks World

Classic blocks world planning domain with state tracking. Companion code for the Planning and Scheduling chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- blocks_plan([on_table(a), on_table(b), clear(a), clear(b)],
               [on(a, b)], Moves).
?- print_state([on(a, b), on_table(b), clear(a)]).
```

## Running Tests

```shell
swipl -g "['tests/test_blocks.plt'], run_tests, halt" -s load.pl
```

## Description

A dedicated blocks world planner that models moving blocks between stacks and the table. States are lists of `on(X, Y)` and `on_table(X)` atoms. The planner uses `blocks_move/3` to generate legal moves (respecting the "clear" constraint — only top blocks can be moved), cycle detection via `blocks_plan_visited/1`, and backtracking search. This classic AI domain illustrates how planning problems map naturally to Prolog's search-and-backtrack paradigm.
