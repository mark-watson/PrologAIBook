# LLM Client

Call Google Gemini and Ollama APIs from Prolog. Companion code for the Integrating with LLMs chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- gemini_generate('What is Prolog?', Response).
?- ollama_generate('Explain backtracking', Response).
```

Requires `GOOGLE_API_KEY` env var for Gemini, and a running Ollama server for local models.

## Running Tests

```shell
swipl -g "['tests/test_llm.pl'], run_tests, halt" -s load.pl
```

## Description

Provides Prolog HTTP clients for two LLM backends. The `gemini.pl` module calls the Google Generative Language API (gemini-2.5-flash) using the `GOOGLE_API_KEY` environment variable. The `ollama.pl` module calls a local Ollama instance for privacy-preserving inference. Both modules use SWI-Prolog's `library(http/http_json)` for JSON request/response handling and return plain text responses extracted from the API's JSON structure.
