# Makefile for strips_planner - STRIPS-style planner
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running strips_planner examples ==="
	$(SWIPL) -g "plan([on_table(a), clear(a), hand_empty], [holding(a)], Plan), format('Plan: ~w~n', [Plan]), halt" -s load.pl

test:
	@echo "=== Running strips_planner tests ==="
	$(SWIPL) -g "['tests/test_strips.pl'], run_tests, halt" -s load.pl

tests: test
