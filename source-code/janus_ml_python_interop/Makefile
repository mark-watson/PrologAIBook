# Makefile for janus_ml - Janus Python-Prolog ML bridge
# Usage: make [all|run|test]
# Note: Janus is loaded through `uv run` so the virtualenv's Python is
# on the path that janus.so expects (see README Troubleshooting for the
# macOS RPATH workaround if janus.so still cannot dlopen).

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running janus_ml examples ==="
	@echo "Note: Requires Janus bridge and Python scikit-learn"
	uv run $(SWIPL) -g "format('janus_ml: module loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running janus_ml tests ==="
	uv run $(SWIPL) -g "['tests/test_janus_ml.pl'], run_tests, halt" -s load.pl

tests: test
