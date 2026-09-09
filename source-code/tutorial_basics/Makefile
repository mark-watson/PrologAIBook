# Makefile for tutorial_basics - Prolog fundamentals
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running tutorial_basics examples ==="
	$(SWIPL) -g " \
	  (parent(tom, bob) -> format('parent(tom, bob): yes~n') ; format('FAILED: parent(tom, bob)~n'), halt(1)), \
	  (grandparent(tom, ann) -> format('grandparent(tom, ann): yes~n') ; format('FAILED: grandparent(tom, ann)~n'), halt(1)), \
	  (sibling(ann, pat) -> format('sibling(ann, pat): yes~n') ; format('FAILED: sibling(ann, pat)~n'), halt(1)), \
	  (my_reverse([1,2,3], R), R = [3,2,1] -> format('reverse([1,2,3]) = ~w~n', [R]) ; format('FAILED: my_reverse~n'), halt(1)), \
	  (my_length([a,b,c], 3) -> format('my_length([a,b,c], 3): yes~n') ; format('FAILED: my_length forward~n'), halt(1)), \
	  (my_length(L, 3), length(L, 3) -> format('my_length(L, 3) generated a 3-element list~n') ; format('FAILED: my_length backward~n'), halt(1)), \
	  halt" -s load.pl

test:
	@echo "=== Running tutorial_basics tests ==="
	$(SWIPL) -g "['tests/test_family.pl', 'tests/test_lists.pl'], run_tests, halt" -s load.pl

tests: test
