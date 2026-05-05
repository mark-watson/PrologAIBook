# Makefile for hybrid_pipeline - Hybrid AI pipeline
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running hybrid_pipeline examples ==="
	$(SWIPL) -g "format('hybrid_pipeline: module loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running hybrid_pipeline tests ==="
	$(SWIPL) -g "['tests/test_pipeline.pl'], run_tests, halt" -s load.pl

tests: test
