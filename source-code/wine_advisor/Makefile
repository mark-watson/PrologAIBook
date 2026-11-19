# Makefile for wine_advisor - Wine recommendation expert system
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running wine_advisor examples ==="
	@$(SWIPL) -g "forall(member(M-P, [red_meat-bold, fish-light, dessert-sweet]), (findall(W, recommend_wine(M, P, W), Ws), format('~w + ~w: ~w~n', [M, P, Ws]))), halt" -s load.pl

test:
	@echo "=== Running wine_advisor tests ==="
	$(SWIPL) -g "['tests/test_wine.pl'], run_tests, halt" -s load.pl

tests: test
