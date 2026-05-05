# Makefile for scryer_dcg - DCG examples for Scryer Prolog
# Usage: make [all|run|test]
# Note: Full examples require Scryer Prolog (not SWI-Prolog)

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running scryer_dcg examples ==="
	@echo "Note: Full DCG examples require Scryer Prolog"
	$(SWIPL) -g "format('scryer_dcg: module loaded~n'), halt" -s load.pl

test:
	@echo "=== Running scryer_dcg tests ==="
	$(SWIPL) -g "['tests/test_scryer_dcg.pl'], run_tests, halt" -s load.pl

tests: test
