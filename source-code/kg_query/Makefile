# Makefile for kg_query - Knowledge graph querying and reasoning
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running kg_query examples ==="
	@echo "--- Direct relations ---"
	@$(SWIPL) -g "relation(mark, uses, prolog), format('mark uses prolog: yes~n'), halt" -s load.pl
	@echo "--- Multi-hop path ---"
	@$(SWIPL) -g "path(mark, swi, Path), format('Path from mark to swi: ~w~n', [Path]), halt" -s load.pl
	@echo "--- Reachable entities from mark ---"
	@$(SWIPL) -g "reachable(mark, Reachable), format('Reachable from mark: ~w~n', [Reachable]), halt" -s load.pl
	@echo "--- All paths from sarah to bert ---"
	@$(SWIPL) -g "all_paths(sarah, bert, Paths), format('Paths from sarah to bert: ~w~n', [Paths]), halt" -s load.pl
	@echo "--- Connected check: mark and swi ---"
	@$(SWIPL) -g "connected(mark, swi), format('mark and swi are connected~n'), halt" -s load.pl
	@echo "--- Entity and relation counts ---"
	@$(SWIPL) -g "findall(_, entity(_,_), Es), length(Es, ECount), findall(_, relation(_,_,_), Rs), length(Rs, RCount), format('~w entities, ~w relations~n', [ECount, RCount]), halt" -s load.pl
	@echo "--- Language dialect chain: clojure to lisp ---"
	@$(SWIPL) -g "path(clojure, lisp, Path), format('Dialect chain: ~w~n', [Path]), halt" -s load.pl
	@echo "--- Cross-domain path: mark to transformer ---"
	@$(SWIPL) -g "path(mark, transformer, Path), format('Path to transformer: ~w~n', [Path]), halt" -s load.pl

test:
	@echo "=== Running kg_query tests ==="
	$(SWIPL) -g "['tests/test_kg_reason.pl'], run_tests, halt" -s load.pl

tests: test