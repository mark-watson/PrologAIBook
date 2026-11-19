# Makefile for scasp_compliance - Explainable compliance rules with s(CASP)
# Usage: make [all|run|test]
# Requires the scasp pack: swipl -g "pack_install(scasp), halt"

SWIPL = swipl

.PHONY: all run test tests check-scasp

all: run test

check-scasp:
	@$(SWIPL) -q -g "(exists_source(library(scasp)) -> halt(0) ; format(user_error, 'The scasp pack is missing. Install it with:~n  swipl -g \"pack_install(scasp), halt\"~n', []), halt(1))"

run: check-scasp
	@echo "=== Running scasp_compliance examples ==="
	@$(SWIPL) -q -g "forall(member(P, [alice, bob, charlie]), run_compliance_check(P)), halt" compliance_check.pl

test: check-scasp
	@echo "=== Running scasp_compliance tests ==="
	$(SWIPL) -g "['tests/test_compliance.pl'], run_tests, halt" compliance_check.pl

tests: test
