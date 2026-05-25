# Makefile for scryer_clp - CLP examples for Scryer Prolog
# Usage: make [all|run|test]
# Uses Scryer Prolog (not SWI-Prolog)

SCRYER = scryer-prolog

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running scryer_clp examples ==="
	$(SCRYER) -g "use_module(prolog/scryer_constraints), magic_square(Square), write('Square = '), write(Square), nl, halt"

test:
	@echo "=== Running scryer_clp tests ==="
	$(SCRYER) -g "use_module('tests/test_scryer_clp'), run_tests, halt"

tests: test

