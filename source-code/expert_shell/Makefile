# Makefile for expert_shell - Expert system shell
# Usage: make [all|run|test]
# Note: 'run' demos the sample wine KB non-interactively

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running expert_shell sample KB demo ==="
	$(SWIPL) -g "load_kb('prolog/sample_kb.pl'), provide_answer(meal, red_meat), provide_answer(bold_preference, yes), consult_expert(C), explain(C), halt" -s load.pl

test:
	@echo "=== Running expert_shell tests ==="
	$(SWIPL) -g "['tests/test_shell.pl'], run_tests, halt" -s load.pl

tests: test
