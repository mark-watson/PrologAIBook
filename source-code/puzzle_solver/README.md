# Puzzle Solver

State-space search applied to the classic Farmer, Fox, Chicken, Grain river crossing puzzle. Companion code for the Search Algorithms chapter.

## Running Examples

```shell
cd source-code/puzzle_solver
swipl -s load.pl
```

```prolog
?- solve_farmer(Moves).
```

## Running Tests

```shell
swipl -g "load_test_files([]), run_tests, halt" -s load.pl
```

## Description

Models the farmer river crossing puzzle as a state-space search problem. Each state is a `state(Farmer, Fox, Chicken, Grain)` term tracking which bank each entity is on. The solver uses Prolog's backtracking to explore moves, applying safety constraints (fox can't be alone with chicken, chicken can't be alone with grain) to prune invalid states. Cycle detection via a visited list prevents infinite loops.
