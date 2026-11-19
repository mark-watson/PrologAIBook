# Makefile for rdf_explorer - RDF data exploration
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running rdf_explorer examples ==="
	@$(SWIPL) -g "load_rdf_file('example.ttl'), format('Subjects:~n'), list_subjects, nl, describe_resource('http://example.org/scryer_prolog'), types_of('http://example.org/scryer_prolog', T), format('~nInferred types of scryer_prolog: ~w~n', [T]), halt" -s load.pl

test:
	@echo "=== Running rdf_explorer tests ==="
	$(SWIPL) -g "['tests/test_rdf.pl'], run_tests, halt" -s load.pl

tests: test
