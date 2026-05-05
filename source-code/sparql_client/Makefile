# Makefile for sparql_client - SPARQL endpoint client
# Usage: make [all|run|test]
# Note: 'run' requires network access to DBpedia

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running sparql_client examples ==="
	@echo "Note: Requires network access to DBpedia SPARQL endpoint"
	$(SWIPL) -g "format('sparql_client: module loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running sparql_client tests ==="
	$(SWIPL) -g "['tests/test_sparql.pl'], run_tests, halt" -s load.pl

tests: test
