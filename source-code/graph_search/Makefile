# Makefile for graph_search - Graph search algorithms (DFS, BFS, A*)
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running graph_search examples ==="
	$(SWIPL) -g "dfs(a, e, P1), format('DFS path: ~w~n', [P1]), bfs(a, e, P2), format('BFS path: ~w~n', [P2]), halt" -s load.pl

test:
	@echo "=== Running graph_search tests ==="
	$(SWIPL) -g "['tests/test_search.pl'], run_tests, halt" -s load.pl

tests: test
