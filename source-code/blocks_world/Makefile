# Makefile for blocks_world - Classic blocks world planning
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running blocks_world examples ==="
	$(SWIPL) -g "blocks_plan([on_table(a), on_table(b), clear(a), clear(b)], [on(a, b)], Moves), format('Plan: ~w~n', [Moves]), print_state([on(a, b), on_table(b), clear(a)]), halt" -s load.pl

test:
	@echo "=== Running blocks_world tests ==="
	$(SWIPL) -g "['tests/test_blocks.plt'], run_tests, halt" -s load.pl

tests: test
