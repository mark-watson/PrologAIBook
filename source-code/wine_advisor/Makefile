# Makefile for wine_advisor - Wine recommendation expert system
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running wine_advisor examples ==="
	$(SWIPL) -g "recommend_wine(red_meat, bold, W1), format('Red meat + bold: ~w~n', [W1]), recommend_wine(fish, light, W2), format('Fish + light: ~w~n', [W2]), halt" -s load.pl

test:
	@echo "=== Running wine_advisor tests ==="
	$(SWIPL) -g "['tests/test_wine.pl'], run_tests, halt" -s load.pl

tests: test
