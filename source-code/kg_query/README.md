# Knowledge Graph Query

Multi-hop reasoning and path finding over knowledge graphs. Companion code for the Knowledge Graphs chapter.

## Running Examples

```shell
cd source-code/kg_query
swipl -s load.pl
```

```prolog
?- relation(mark, uses, prolog).
?- path(mark, swi, Path).
?- connected(mark, swi).
```

## Running Tests

```shell
swipl -g "load_test_files([]), run_tests, halt" -s load.pl
```

## Description

Extends the knowledge graph concept with multi-hop reasoning capabilities. The `kg_reason.pl` module stores entities with types and directional relations, then provides `path/3` to find chains of relations connecting two entities and `connected/2` to check reachability in either direction. The example knowledge graph models relationships between people, programming languages, fields, and implementations. This showcases Prolog's natural advantage for graph traversal — recursive path finding with backtracking is trivial to express declaratively.
