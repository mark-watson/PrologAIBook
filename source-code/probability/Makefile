# Makefile for probability - Bayesian and Frequentist probability toolkit
# Usage: make [all|run|freq|test]

SWIPL = swipl

.PHONY: all run freq test tests

all: run freq test

run:
	@echo "=== Running Bayesian medical screening example ==="
	$(SWIPL) -g "run_medical_example, halt" -s load.pl

freq:
	@echo "=== Running Frequentist medical screening example ==="
	$(SWIPL) -g "run_frequentist_demo, halt" -s load.pl

test:
	@echo "=== Running probability tests ==="
	$(SWIPL) -g "['tests/test_probability.pl'], run_tests, halt" -s load.pl

tests: test
