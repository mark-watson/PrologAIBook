# Makefile for structured_output - JSON to Prolog facts conversion
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests llm

all: run test

run:
	@echo "=== Running structured_output examples ==="
	@$(SWIPL) -g "json_string_to_facts('{\"entities\":[{\"name\":\"Paris\",\"type\":\"city\"}]}'), forall(extracted_entity(N, T), format('Entity: ~w (~w)~n', [N, T])), halt" -s load.pl

test:
	@echo "=== Running structured_output tests ==="
	$(SWIPL) -g "['tests/test_json_facts.pl'], run_tests, halt" -s load.pl

tests: test

# Needs GOOGLE_API_KEY: ask Gemini to extract facts from a sentence.
llm:
	@$(SWIPL) -g "extract_facts('Ada Lovelace worked with Charles Babbage in London.', C), get_dict(entities, C, NE), get_dict(relations, C, NR), format('Extracted ~w entities and ~w relations~n', [NE, NR]), forall(extracted_entity(N, T), format('entity: ~w (~w)~n', [N, T])), forall(extracted_relation(S, P, O), format('relation: ~w ~w ~w~n', [S, P, O])), halt" -s load.pl
