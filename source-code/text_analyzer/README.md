# Text Analyzer

Named entity recognition and text categorization using gazetteer lookup and bag-of-words scoring. Companion code for the NLP with DCGs chapter.

## Running Examples

```shell
cd source-code/text_analyzer
swipl -s load.pl
```

```prolog
?- find_entities(['John', walks, in, 'London'], Entities).
?- categorize([president, election, vote, market], Categories).
```

## Running Tests

```shell
swipl -g "['tests/test_ner.pl'], run_tests, halt" -s load.pl
```

## Description

Implements two lightweight NLP techniques in pure Prolog. The `ner.pl` module performs named entity recognition by matching input words against gazetteer lists of known person and place names, returning typed `entity(Type, Name)` terms. The `categorizer.pl` module uses a bag-of-words approach with keyword lists for categories (politics, sports, technology, economy), scoring input text against each category and returning ranked results. Both modules are intentionally simple to demonstrate the pattern before scaling up with LLM or Janus-based approaches in later chapters.
