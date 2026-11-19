# Makefile for blocks_world - Classic blocks world planning
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running blocks_world examples ==="
	@$(SWIPL) -g "blocks_plan([on_table(a), on_table(b)], [on(a, b)], M1), format('Stack a on b: ~w~n', [M1]), blocks_plan([on(c, a), on_table(a), on_table(b)], [on(a, b), on(b, c)], M2), format('Sussman anomaly (BFS): ~w~n', [M2]), blocks_plan_dfs([on(c, a), on_table(a), on_table(b)], [on(a, b), on(b, c)], M3), length(M3, N3), format('Sussman anomaly (DFS): ~w moves: ~w~n', [N3, M3]), halt" -s load.pl

test:
	@echo "=== Running blocks_world tests ==="
	$(SWIPL) -g "['tests/test_blocks.plt'], run_tests, halt" -s load.pl

tests: test
