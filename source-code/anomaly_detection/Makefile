# Makefile for anomaly_detection - Gaussian anomaly detection on Wisconsin cancer data
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running anomaly detection on Wisconsin cancer data ==="
	$(SWIPL) -g "once((load_wisconsin_data(R), train_model(R, _))), halt" -s load.pl

test:
	@echo "=== Running anomaly_detection tests ==="
	$(SWIPL) -g "['tests/test_anomaly_detection.pl'], run_tests, halt" -s load.pl

tests: test
