# Makefile for puzzle_solver - Farmer-Fox-Chicken-Grain river crossing
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running puzzle_solver examples ==="
	$(SWIPL) -g "solve_farmer(Moves), format('Farmer puzzle solution: ~w~n', [Moves]), halt" -s load.pl

test:
	@echo "=== Running puzzle_solver tests ==="
	$(SWIPL) -g "['tests/test_farmer.pl'], run_tests, halt" -s load.pl

tests: test
