# Makefile for proof_trees - Proof tree construction and display
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running proof_trees examples ==="
	$(SWIPL) -g "format('proof_trees: module loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running proof_trees tests ==="
	$(SWIPL) -g "['tests/test_proof_tree.pl'], run_tests, halt" -s load.pl

tests: test
