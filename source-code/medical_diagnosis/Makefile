# Makefile for medical_diagnosis - Medical diagnosis expert system
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running medical_diagnosis examples ==="
	$(SWIPL) -g "diagnose([fever, cough, fatigue, body_aches], R1), format('Diagnosis 1: ~w~n', [R1]), diagnose([sneezing, runny_nose, sore_throat], R2), format('Diagnosis 2: ~w~n', [R2]), halt" -s load.pl

test:
	@echo "=== Running medical_diagnosis tests ==="
	$(SWIPL) -g "['tests/test_diagnosis.pl'], run_tests, halt" -s load.pl

tests: test
