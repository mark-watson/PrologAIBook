# Makefile for research_assistant - AI research assistant
# Usage: make [all|run|test]
# Note: 'run' needs network access and GOOGLE_API_KEY

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running research_assistant examples ==="
	@$(SWIPL) -g "research('Who designed the Warren Abstract Machine and when?', A), format('~n~w~n', [A]), halt" -s load.pl

test:
	@echo "=== Running research_assistant tests ==="
	$(SWIPL) -g "['tests/test_assistant.pl'], run_tests, halt" -s load.pl

tests: test
