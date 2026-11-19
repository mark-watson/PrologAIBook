# Makefile for prolog_wasm_web - SWI-Prolog in the browser via WebAssembly
# Usage: make [serve|test]
# 'serve' starts a local web server; open http://localhost:8000

SWIPL = swipl

.PHONY: serve test tests

serve:
	@echo "Open http://localhost:8000 (Ctrl-C to stop)"
	python3 -m http.server 8000 --directory .

test:
	@echo "=== Testing rules.pl with native SWI-Prolog ==="
	cd tests && $(SWIPL) -g "['test_rules.pl'], run_tests, halt"

tests: test
