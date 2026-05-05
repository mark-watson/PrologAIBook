# Makefile for scryer_clp - CLP examples for Scryer Prolog
# Usage: make [all|run|test]
# Note: Full examples require Scryer Prolog (not SWI-Prolog)

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running scryer_clp examples ==="
	@echo "Note: Full CLP(Z) examples require Scryer Prolog"
	$(SWIPL) -g "format('scryer_clp: module loaded (limited in SWI-Prolog)~n'), halt" -s load.pl

test:
	@echo "=== Running scryer_clp tests ==="
	$(SWIPL) -g "['tests/test_scryer_clp.pl'], run_tests, halt" -s load.pl

tests: test
