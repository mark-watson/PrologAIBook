# Makefile for inference_engine - Forward and backward chaining inference
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running inference_engine examples ==="
	$(SWIPL) -g "add_fact(raining), add_rule([raining], wet_ground), forward_chain, (derived_fact(wet_ground) -> format('Derived: wet_ground~n') ; format('Not derived~n')), halt" -s load.pl

test:
	@echo "=== Running inference_engine tests ==="
	$(SWIPL) -g "['tests/test_inference.pl'], run_tests, halt" -s load.pl

tests: test
