# Makefile for rdf_explorer - RDF data exploration
# Usage: make [all|run|test]
# Note: 'run' requires RDF/TTL data files

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running rdf_explorer examples ==="
	$(SWIPL) -g "format('rdf_explorer: module loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running rdf_explorer tests ==="
	$(SWIPL) -g "['tests/test_rdf.pl'], run_tests, halt" -s load.pl

tests: test
