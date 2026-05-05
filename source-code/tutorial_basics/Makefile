# Makefile for tutorial_basics - Prolog fundamentals
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running tutorial_basics examples ==="
	$(SWIPL) -g " \
	  (parent(tom, bob) -> format('parent(tom, bob): yes~n') ; true), \
	  (grandparent(tom, ann) -> format('grandparent(tom, ann): yes~n') ; true), \
	  (sibling(ann, pat) -> format('sibling(ann, pat): yes~n') ; true), \
	  my_reverse([1,2,3], R), format('reverse([1,2,3]) = ~w~n', [R]), \
	  halt" -s load.pl

test:
	@echo "=== Running tutorial_basics tests ==="
	$(SWIPL) -g "['tests/test_family.pl'], run_tests, halt" -s load.pl

tests: test
