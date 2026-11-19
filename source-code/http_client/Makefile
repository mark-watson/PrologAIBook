# Makefile for http_client - HTTP client and JSON parsing
# Usage: make [all|run|test]
# Note: 'run' examples require network access

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running http_client examples ==="
	@$(SWIPL) -g "parse_json_string('{\"name\":\"test\",\"value\":42}', Dict), format('Parsed: ~p~n', [Dict]), http_get_json('https://jsonplaceholder.typicode.com/todos/1', Todo), get_dict(title, Todo, Title), format('GET todo title: ~w~n', [Title]), http_post_json('https://jsonplaceholder.typicode.com/posts', _{title:\"Prolog\", body:\"hello\", userId:1}, Reply), get_dict(id, Reply, Id), format('POST reply id: ~w~n', [Id]), halt" -s load.pl

test:
	@echo "=== Running http_client tests ==="
	$(SWIPL) -g "['tests/test_json.pl'], run_tests, halt" -s load.pl

tests: test
