# Makefile for inference_engine - Forward and backward chaining inference
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running inference_engine examples ==="
	@$(SWIPL) -g "reset_kb, add_fact(raining), add_rule([raining], wet_ground), add_rule([wet_ground], slippery), forward_chain, findall(F, derived_fact(F), Fs), format('Forward chaining facts: ~w~n', [Fs]), reset_kb, reset_bc_kb, assertz(backward_chain:bc_fact(raining)), assertz(backward_chain:bc_rule([raining], wet_ground)), assertz(backward_chain:bc_rule([wet_ground], slippery)), prove(slippery, P), format('Backward chaining proof: ~w~n', [P]), explanations(abduction:grass_is_wet, [rained, sprinkler_was_on], E), format('Explanations for wet grass: ~w~n', [E]), (flies(tweety) -> format('tweety flies~n') ; true), halt" -s load.pl

test:
	@echo "=== Running inference_engine tests ==="
	$(SWIPL) -g "['tests/test_inference.pl', 'tests/test_reasoning.pl'], run_tests, halt" -s load.pl

tests: test
