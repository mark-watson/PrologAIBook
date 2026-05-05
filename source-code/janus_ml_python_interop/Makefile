# Makefile for janus_ml - Janus Python-Prolog ML bridge
# Usage: make [all|run|test]
# Note: 'run' requires Python with scikit-learn and Janus bridge

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running janus_ml examples ==="
	@echo "Note: Requires Janus bridge and Python scikit-learn"
	$(SWIPL) -g "format('janus_ml: module loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running janus_ml tests ==="
	$(SWIPL) -g "['tests/test_janus_ml.pl'], run_tests, halt" -s load.pl

tests: test
