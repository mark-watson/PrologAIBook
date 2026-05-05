# Makefile for dcg_parser - Natural language parsing with DCGs
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running dcg_parser examples ==="
	$(SWIPL) -g "parse_sentence([the, dog, chases, the, cat], Tree), format('Parse: ~w~n', [Tree]), halt" -s load.pl

test:
	@echo "=== Running dcg_parser tests ==="
	$(SWIPL) -g "['tests/test_grammar.pl'], run_tests, halt" -s load.pl

tests: test
