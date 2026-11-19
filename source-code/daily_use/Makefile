# Makefile for daily_use - Interactive Gemini REPL with cache
# Usage: make [run|test]
# Requires: GOOGLE_API_KEY environment variable

SWIPL = swipl

.PHONY: all run test tests ask

all: test

run:
	@echo "=== Starting daily_use REPL ==="
	@echo "Note: Requires GOOGLE_API_KEY"
	$(SWIPL) run.pl

# One question without the REPL:  make ask Q="What is unification?"
ask:
	@$(SWIPL) -g "ask('$(Q)', false, A), format('~w~n', [A]), halt" -s load.pl

test:
	@echo "=== Running daily_use tests ==="
	$(SWIPL) -g "['tests/test_daily_use.pl'], run_tests, halt" -s load.pl

tests: test
