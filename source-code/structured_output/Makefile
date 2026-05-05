# Makefile for structured_output - JSON to Prolog facts conversion
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running structured_output examples ==="
	$(SWIPL) -g "json_string_to_facts('{"entities":[{"name":"Paris","type":"city"}]}'), forall(extracted_entity(N, T), format('Entity: ~w (~w)~n', [N, T])), halt" -s load.pl

test:
	@echo "=== Running structured_output tests ==="
	$(SWIPL) -g "['tests/test_json_facts.pl'], run_tests, halt" -s load.pl

tests: test
