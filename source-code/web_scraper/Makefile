# Makefile for web_scraper - Web page scraping
# Usage: make [all|run|test]
# Note: 'run' requires network access

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running web_scraper examples ==="
	@echo "Note: Requires network access"
	@$(SWIPL) -g "fetch_page('https://www.swi-prolog.org', DOM), extract_links(DOM, Links), length(Links, N), format('Found ~w links on swi-prolog.org~n', [N]), extract_text(DOM, Text), sub_atom(Text, 0, 200, _, Start), format('Text starts: ~w...~n', [Start]), halt" -s load.pl

test:
	@echo "=== Running web_scraper tests ==="
	$(SWIPL) -g "['tests/test_scraper.pl'], run_tests, halt" -s load.pl

tests: test
