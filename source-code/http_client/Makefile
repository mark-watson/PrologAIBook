# Makefile for http_client - HTTP client and JSON parsing
# Usage: make [all|run|test]
# Note: 'run' examples require network access

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running http_client examples ==="
	$(SWIPL) -g "parse_json_string('{\"name\":\"test\",\"value\":42}', Dict), format('Parsed: ~w~n', [Dict]), halt" -s load.pl

test:
	@echo "=== Running http_client tests ==="
	$(SWIPL) -g "['tests/test_json.pl'], run_tests, halt" -s load.pl

tests: test
