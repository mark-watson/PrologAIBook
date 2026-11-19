# Makefile for llm_logic_guardrails - Prolog rules that check LLM output
# Usage: make [all|run|test|repair]

SWIPL = swipl

.PHONY: all run test tests repair

all: run test

# Python harness: Python calls Prolog through the janus-swi package.
run:
	uv run verify_llm.py

test:
	@echo "=== Running llm_logic_guardrails tests ==="
	$(SWIPL) -g "['tests/test_guardrails.pl'], run_tests, halt" -s load.pl

# Needs GOOGLE_API_KEY: ask Gemini for a portfolio, repair until valid.
repair:
	@$(SWIPL) -g "(safe_portfolio(72, low, \"The client wants 25% of the portfolio in crypto.\", 3, J) -> format('Accepted:~n~w~n', [J]) ; format('No valid portfolio in 3 tries~n')), halt" -s load.pl
