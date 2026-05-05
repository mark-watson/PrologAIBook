# Makefile for meta_interp - Meta-interpreters (vanilla and bounded)
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running meta_interp examples ==="
	$(SWIPL) -g "assert((likes(john, mary) :- true)), mi_solve(likes(john, mary)), format('Vanilla solve: likes(john, mary) succeeded~n'), mi_bounded(likes(john, mary), 5), format('Bounded solve: succeeded~n'), halt" -s load.pl

test:
	@echo "=== Running meta_interp tests ==="
	$(SWIPL) -g "['tests/test_meta.pl'], run_tests, halt" -s load.pl

tests: test
