# Makefile for scryer_dcg - DCG examples for Scryer Prolog
# Usage: make [all|run|test]
# Uses Scryer Prolog (not SWI-Prolog)

SCRYER = scryer-prolog

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running scryer_dcg examples ==="
	$(SCRYER) -g "use_module('prolog/text_dcg'), parse_csv_line(\"a,b,c\", F), write(F), nl, halt"

test:
	@echo "=== Running scryer_dcg tests ==="
	$(SCRYER) -g "use_module('tests/test_scryer_dcg'), run_tests, halt"

tests: test
