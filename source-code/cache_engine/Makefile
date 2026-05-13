# Makefile for cache_engine - Persistent LLM cache using SQLite
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running cache_engine example ==="
	$(SWIPL) -g "cache_open(example_cache, C), cache_add(C, 'The quick brown fox'), cache_add(C, 'Hello world'), cache_lookup(C, [fox], R), format('Lookup fox: ~w~n', [R]), cache_count(C, N), format('Count: ~w~n', [N]), cache_close(C), halt" -s load.pl

test:
	@echo "=== Running cache_engine tests ==="
	$(SWIPL) -g "['tests/test_cache_engine.pl'], run_tests, halt" -s load.pl

tests: test
