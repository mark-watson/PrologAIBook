# Makefile for prob_reasoning - Probabilities propagated through rules
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running prob_reasoning examples ==="
	@$(SWIPL) -g "prob_query(cloudy, P1), format('P(cloudy) = ~w~n', [P1]), prob_query(rain, P2), format('P(rain) = ~w~n', [P2]), prob_query(storm, P3), format('P(storm) = ~w~n', [P3]), prob_query(tornado_risk, P4), format('P(tornado_risk) = ~4f~n', [P4]), prob([rain=true], [wet_grass=true], P5), format('Bayes net P(rain | wet_grass) = ~4f~n', [P5]), halt" -s load.pl

test:
	@echo "=== Running prob_reasoning tests ==="
	$(SWIPL) -g "['tests/test_prob.pl', 'tests/test_bayes_net.pl'], run_tests, halt" -s load.pl

tests: test
