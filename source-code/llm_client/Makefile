# Makefile for llm_client - LLM API client (Gemini, Ollama)
# Usage: make [all|run|test]
# Note: 'run' requires GOOGLE_API_KEY or local Ollama server

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running llm_client examples ==="
	@echo "Note: needs GOOGLE_API_KEY and a local Ollama server with qwen3:1.7b"
	@$(SWIPL) -g "(gemini_generate('In one sentence, what is Prolog?', G) -> format('Gemini: ~w~n', [G]) ; true), (ollama_generate('In one sentence, what is Prolog?', O) -> format('Ollama: ~w~n', [O]) ; true), halt" -s load.pl

test:
	@echo "=== Running llm_client tests ==="
	$(SWIPL) -g "['tests/test_llm.pl'], run_tests, halt" -s load.pl

tests: test
