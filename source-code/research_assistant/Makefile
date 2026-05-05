# Makefile for research_assistant - AI research assistant
# Usage: make [all|run|test]
# Note: Full 'run' requires LLM API access

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running research_assistant examples ==="
	$(SWIPL) -g "format('research_assistant: module loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running research_assistant tests ==="
	$(SWIPL) -g "['tests/test_assistant.pl'], run_tests, halt" -s load.pl

tests: test
