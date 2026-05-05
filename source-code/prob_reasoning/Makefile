# Makefile for prob_reasoning - Probabilistic reasoning with certainty factors
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running prob_reasoning examples ==="
	$(SWIPL) -g "prob_query(cloudy, P1), format('P(cloudy) = ~w~n', [P1]), prob_query(rain, P2), format('P(rain) = ~w~n', [P2]), prob_query(storm, P3), format('P(storm) = ~w~n', [P3]), halt" -s load.pl

test:
	@echo "=== Running prob_reasoning tests ==="
	$(SWIPL) -g "['tests/test_prob.pl'], run_tests, halt" -s load.pl

tests: test
