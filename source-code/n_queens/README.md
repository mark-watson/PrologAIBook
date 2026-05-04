# N-Queens

The N-Queens problem solved with CLP(FD) constraints. Companion code for the Constraint Logic Programming chapter.

## Running Examples

```shell
cd source-code/n_queens
swipl -s load.pl
```

```prolog
?- n_queens(8, Queens).
?- n_queens(4, Queens).
?- aggregate_all(count, n_queens(8, _), Count).
```

## Running Tests

```shell
swipl -g "load_test_files([]), run_tests, halt" -s load.pl
```

## Description

Places N queens on an N×N chessboard so no two queens attack each other. The solution uses CLP(FD) constraints to enforce that no two queens share a row, column, or diagonal. The `safe_queen/3` predicate elegantly encodes diagonal constraints using arithmetic differences. Compare the conciseness of this declarative solution against the equivalent imperative backtracking approach — CLP(FD) propagation dramatically prunes the search space, making even large N values practical.
