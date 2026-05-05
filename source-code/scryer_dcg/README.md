# Scryer DCG

Large-scale text processing with Scryer Prolog's memory-efficient DCGs. Companion code for the Scryer Prolog chapter.

## Running Examples

Run with Scryer Prolog (not SWI-Prolog):

```shell
scryer-prolog prolog/text_dcg.pl
```

```prolog
?- parse_csv_line("hello,world,test", Fields).
?- parse_key_value("name=Mark", Pair).
```

## Running Tests

```shell
scryer-prolog -g "use_module('tests/test_scryer_dcg'), run_tests, halt"
```

## Description

Demonstrates Scryer Prolog's advantage for text processing: its memory-efficient string representation (strings as lists of characters without copying) makes DCG-based parsing practical for large inputs. The `text_dcg.pl` module implements CSV line parsing, key-value pair extraction, and email extraction using pure DCG rules. These examples highlight when to choose Scryer over SWI-Prolog for text-heavy workloads.
