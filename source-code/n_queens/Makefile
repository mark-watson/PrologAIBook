# Makefile for n_queens - N-Queens puzzle solver
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running n_queens examples ==="
	$(SWIPL) -g "n_queens(8, Queens), format('8-Queens: ~w~n', [Queens]), aggregate_all(count, n_queens(8, _), Count), format('Total 8-Queens solutions: ~w~n', [Count]), halt" -s load.pl

test:
	@echo "=== Running n_queens tests ==="
	$(SWIPL) -g "['tests/test_queens.pl'], run_tests, halt" -s load.pl

tests: test
