# Makefile for sparql_client - SPARQL endpoint client
# Usage: make [all|run|test]
# Note: 'run' requires network access to DBpedia and Wikidata

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running sparql_client examples ==="
	@echo "Note: needs network access to DBpedia and Wikidata"
	@$(SWIPL) -g "dbpedia_description('Prolog', D), format('DBpedia: Prolog is a ~w~n', [D]), wikidata_query('SELECT ?l WHERE { wd:Q163468 rdfs:label ?l . FILTER(lang(?l) = \"fr\") }', row(L)), literal_text(L, FR), format('Wikidata: the French label of Q163468 is ~w~n', [FR]), halt" -s load.pl

test:
	@echo "=== Running sparql_client tests ==="
	$(SWIPL) -g "['tests/test_sparql.pl'], run_tests, halt" -s load.pl

tests: test
