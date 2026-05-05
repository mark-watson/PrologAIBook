# Makefile for reactive_agent - Reactive AI agent framework
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running reactive_agent examples ==="
	$(SWIPL) -g "define_goal(answer_found), register_tool(search, search_web/1), format('Agent configured with goal and tool~n'), halt" -s load.pl

test:
	@echo "=== Running reactive_agent tests ==="
	$(SWIPL) -g "['tests/test_agent.pl'], run_tests, halt" -s load.pl

tests: test
