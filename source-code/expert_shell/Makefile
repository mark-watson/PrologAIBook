# Makefile for expert_shell - Expert system shell
# Usage: make [all|run|test]
# Note: 'run' starts an interactive session

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running expert_shell (interactive) ==="
	@echo "Type: consult_expert(Conclusion). then explain(Conclusion)."
	$(SWIPL) -s load.pl

test:
	@echo "=== Running expert_shell tests ==="
	$(SWIPL) -g "['tests/test_shell.pl'], run_tests, halt" -s load.pl

tests: test
