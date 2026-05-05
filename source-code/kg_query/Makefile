# Makefile for kg_query - Knowledge graph querying and reasoning
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running kg_query examples ==="
	$(SWIPL) -g "relation(mark, uses, prolog), format('mark uses prolog: yes~n'), path(mark, swi, Path), format('Path: ~w~n', [Path]), halt" -s load.pl

test:
	@echo "=== Running kg_query tests ==="
	$(SWIPL) -g "['tests/test_kg_reason.pl'], run_tests, halt" -s load.pl

tests: test
