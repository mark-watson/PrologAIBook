# Makefile for text_analyzer - Named entity recognition and text categorization
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running text_analyzer examples ==="
	@$(SWIPL) -g "find_entities(['John', flew, from, 'New', 'York', to, 'London'], Entities), format('Entities: ~w~n', [Entities]), categorize([president, election, vote, market], Categories), format('Categories: ~w~n', [Categories]), summarize([[the, hospital, installed, a, new, software, database, system], [technology, startups, are, building, quantum, encryption, algorithms], [cats, and, dogs, run, in, the, local, park]], technology, S), format('Technology summary: ~w~n', [S]), halt" -s load.pl

test:
	@echo "=== Running text_analyzer tests ==="
	$(SWIPL) -g "['tests/test_ner.pl', 'tests/test_categorizer.pl'], run_tests, halt" -s load.pl

tests: test
