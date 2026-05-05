# Research Assistant

An agent combining web search, LLM summarization, and Prolog reasoning. Companion code for the Building AI Agents chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- research("What is Prolog?", Answer).
```

## Running Tests

```shell
swipl -g "['tests/test_assistant.pl'], run_tests, halt" -s load.pl
```

## Description

A practical agent case study that chains together web search (via REST APIs), LLM summarization (Gemini/Ollama), and Prolog knowledge storage and reasoning. The intended workflow: parse the question → search the web → summarize results via LLM → store structured knowledge as Prolog facts → reason over the knowledge base to produce an answer. Currently a skeleton awaiting integration with the `llm_client` and `http_client` projects.
