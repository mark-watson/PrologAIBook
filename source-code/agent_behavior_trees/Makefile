# Makefile for agent_behavior_trees - Behavior tree engine and robot agent
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running behavior tree robot simulation ==="
	@$(SWIPL) -g "run_simulation(12), halt" -s load.pl

test:
	@echo "=== Running agent_behavior_trees tests ==="
	$(SWIPL) -g "['tests/test_bt.pl'], run_tests, halt" -s load.pl

tests: test
