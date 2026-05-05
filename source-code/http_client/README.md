# HTTP Client

REST API consumption and JSON processing with SWI-Prolog's HTTP libraries. Companion code for the Web Clients and REST APIs chapter.

## Running Examples

```shell
cd source-code/http_client
swipl -s load.pl
```

```prolog
?- http_get_json('https://jsonplaceholder.typicode.com/todos/1', Result).
?- parse_json_string('{"name":"test","value":42}', Dict).
```

## Running Tests

```shell
swipl -g "['tests/test_json.pl'], run_tests, halt" -s load.pl
```

## Description

Demonstrates SWI-Prolog's built-in HTTP client capabilities for consuming web APIs. The `rest_client.pl` module wraps `library(http/http_client)` and `library(http/http_json)` for making GET and POST requests with automatic JSON parsing into SWI-Prolog dicts. The `json_utils.pl` module provides utilities for parsing JSON strings and converting dicts to key-value pair lists. These building blocks are used throughout later chapters for LLM API calls, web search integration, and SPARQL queries.
