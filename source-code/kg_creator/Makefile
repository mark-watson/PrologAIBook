# Makefile for kg_creator - Knowledge graph builder
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running kg_creator examples ==="
	$(SWIPL) -g "add_triple(john, works_at, acme), add_triple(acme, located_in, london), query_triples(john, _, X), format('john -> ~w~n', [X]), halt" -s load.pl

test:
	@echo "=== Running kg_creator tests ==="
	$(SWIPL) -g "['tests/test_kg.pl'], run_tests, halt" -s load.pl

tests: test
