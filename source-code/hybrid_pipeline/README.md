# Hybrid Pipeline

Python NLP preprocessing combined with Prolog reasoning via Janus. Companion code for the Janus Python Bridge chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- run_pipeline("John Smith visited London last week", Result).
```

Requires SWI-Prolog with Janus support and Python with spaCy installed.

## Running Tests

```shell
swipl -g "['tests/test_pipeline.pl'], run_tests, halt" -s load.pl
```

## Description

A full hybrid AI pipeline: Python/spaCy performs named entity recognition on input text, the extracted entities are asserted as Prolog facts, and Prolog rules classify them (e.g., persons as `important_person`, locations as `location`). This demonstrates the architecture where Python handles statistical NLP and Prolog handles symbolic reasoning — each language used for what it does best.
