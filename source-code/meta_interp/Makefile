# Makefile for meta_interp - Meta-interpreters (vanilla and bounded)
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running meta_interp examples ==="
	@$(SWIPL) -g "mi_solve_proof(sample_kb, grandparent(tom, W), P), format('Vanilla proof: ~w~n', [P]), findall(X, mi_bfs(sample_kb, path(a, X), 1000), Xs), sort(Xs, S), format('Breadth-first path(a, X): ~w~n', [S]), best_cf(sample_kb, see_doctor, CF), format('Certainty of see_doctor: ~2f~n', [CF]), format('Trace of grandparent(tom, W):~n'), mi_trace(sample_kb, grandparent(tom, _)), halt" -s load.pl

test:
	@echo "=== Running meta_interp tests ==="
	$(SWIPL) -g "['tests/test_meta.pl'], run_tests, halt" -s load.pl

tests: test
