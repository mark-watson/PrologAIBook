# Makefile for kg_creator - Knowledge graph builder
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests enrich

all: run test

run:
	@echo "=== Running kg_creator examples ==="
	@$(SWIPL) -g "add_triple(john, works_at, acme), add_triple(acme, located_in, london), add_triple(john, age, 42), query_triples(john, works_at, X), format('john works at ~w~n', [X]), format('~nN-Triples:~n'), export_rdf('/dev/stdout'), format('~nCypher:~n'), export_cypher('/dev/stdout'), halt" -s load.pl

# Needs network access: asks DBpedia who designed some languages.
enrich:
	@$(SWIPL) -g "forall(member(L, [python, lisp, prolog]), (findall(D, query_designer(L, D), Ds), format('~w designed by: ~w~n', [L, Ds]))), halt" -s load.pl

test:
	@echo "=== Running kg_creator tests ==="
	$(SWIPL) -g "['tests/test_kg.pl'], run_tests, halt" -s load.pl

tests: test
