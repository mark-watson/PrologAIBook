# Makefile for llm_client - LLM API client (Gemini, Ollama)
# Usage: make [all|run|test]
# Note: 'run' requires GOOGLE_API_KEY or local Ollama server

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running llm_client examples ==="
	@echo "Note: Requires GOOGLE_API_KEY or local Ollama"
	$(SWIPL) -g "format('llm_client: modules loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running llm_client tests ==="
	$(SWIPL) -g "['tests/test_llm.pl'], run_tests, halt" -s load.pl

tests: test
