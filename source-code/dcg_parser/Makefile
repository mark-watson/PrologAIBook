# Makefile for dcg_parser - Natural language parsing with DCGs
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running dcg_parser examples ==="
	@$(SWIPL) -g "tokenize('The dog chases the cat.', W), format('Tokens: ~w~n', [W]), parse_sentence(W, Tree), format('Parse: ~w~n', [Tree]), sentence_logic([every, dog, chases, a, cat], F), format('Logic: ~w~n', [F]), answer([every, person, likes, a, dog], A), format('Every person likes a dog? ~w~n', [A]), halt" -s load.pl

test:
	@echo "=== Running dcg_parser tests ==="
	$(SWIPL) -g "['tests/test_grammar.pl', 'tests/test_tokenizer.pl', 'tests/test_semantics.pl'], run_tests, halt" -s load.pl

tests: test
