# Makefile for job_scheduler - Constraint-based job scheduling
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running job_scheduler examples ==="
	$(SWIPL) -g "schedule_jobs([job(a, 3, 10), job(b, 2, 8), job(c, 4, 20)], Schedule), format('Schedule: ~w~n', [Schedule]), halt" -s load.pl

test:
	@echo "=== Running job_scheduler tests ==="
	$(SWIPL) -g "['tests/test_scheduler.pl'], run_tests, halt" -s load.pl

tests: test
