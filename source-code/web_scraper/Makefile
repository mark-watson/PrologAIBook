# Makefile for web_scraper - Web page scraping
# Usage: make [all|run|test]
# Note: 'run' requires network access

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running web_scraper examples ==="
	@echo "Note: Requires network access"
	$(SWIPL) -g "format('web_scraper: module loaded successfully~n'), halt" -s load.pl

test:
	@echo "=== Running web_scraper tests ==="
	$(SWIPL) -g "['tests/test_scraper.pl'], run_tests, halt" -s load.pl

tests: test
