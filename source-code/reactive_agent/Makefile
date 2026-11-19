# Makefile for reactive_agent - Reactive AI agent framework
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running reactive_agent examples ==="
	@$(SWIPL) -g "setup_world(a, [a, b]), run_agent(vacuum_world, 10), halt" -s load.pl

test:
	@echo "=== Running reactive_agent tests ==="
	$(SWIPL) -g "['tests/test_agent.pl'], run_tests, halt" -s load.pl

tests: test
