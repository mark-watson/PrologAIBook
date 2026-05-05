# RDF Explorer

Load, query, and reason over RDF data using SWI-Prolog's semweb library. Companion code for the Semantic Web and Linked Data chapter.

## Running Examples

```shell
cd source-code/rdf_explorer
swipl -s load.pl
```

```prolog
?- load_rdf_file('example.ttl').
?- list_subjects.
?- describe_resource('http://example.org/person/1').
?- query_rdf(S, P, O).
```

## Running Tests

```shell
swipl -g "['tests/test_rdf.pl'], run_tests, halt" -s load.pl
```

## Description

Uses SWI-Prolog's built-in `library(semweb/rdf_db)` and `library(semweb/turtle)` to load RDF data from Turtle files and query it using Prolog's pattern matching. The `rdf_loader.pl` module provides convenience predicates for loading files, querying triples, listing all subjects, and describing individual resources. SWI-Prolog's semweb library is one of the most mature RDF implementations in any language, making Prolog a natural choice for semantic web applications that require both data access and logical reasoning.
