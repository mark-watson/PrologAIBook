# Proof Trees

Visual explanation of reasoning through proof tree construction. Companion code for the Meta-Interpreters chapter.

## Running Examples

```shell
swipl -s load.pl
```

The `proof_tree.pl` module auto-loads a large sample dataset (`prolog/sample_data.pl`)
containing a 5-generation family tree with multiple relationship predicates.
Try these queries:

```prolog
% Direct fact
?- prove_with_tree(parent(adam, john), Tree), print_proof(Tree).

% Conjunction (two subgoals)
?- prove_with_tree(grandparent(john, ann), Tree), print_proof(Tree).

% Recursive predicate (5-generation ancestor chain)
?- prove_with_tree(ancestor(adam, grace), Tree), print_proof(Tree).

% Conjunction with built-in comparison
?- prove_with_tree(sibling(ann, bob), Tree), print_proof(Tree).

% Multi-step derivation (grandparent + parent)
?- prove_with_tree(great_grandparent(adam, ann), Tree), print_proof(Tree).

% Multiple subgoals with negation-as-failure
?- prove_with_tree(cousin(carol, emma), Tree), print_proof(Tree).

% Aunt/uncle relationship (sibling of parent)
?- prove_with_tree(aunt_uncle(michael, ann), Tree), print_proof(Tree).

% Descendant via ancestor (reverse lookup)
?- prove_with_tree(descendant(grace, adam), Tree), print_proof(Tree).
```

## Sample Data

The `prolog/sample_data.pl` file provides an extended 5-generation family tree:

| Predicate | Type | Description |
|---|---|---|
| `parent/2` | Facts (28) | Direct parent-child relationships |
| `grandparent/2` | Rule | Conjunction of two `parent/2` subgoals |
| `great_grandparent/2` | Rule | Multi-step derivation via `grandparent` and `parent` |
| `ancestor/2` | Rule (recursive) | Two clauses: direct parent or recursive ancestor |
| `descendant/2` | Rule | Inverse of `ancestor/2` |
| `sibling/2` | Rule | Shared parent with inequality check (`\=`) |
| `cousin/2` | Rule | Shared grandparent, not siblings (uses `\+`) |
| `aunt_uncle/2` | Rule | Sibling of a parent |

## Running Tests

```shell
swipl -g "['tests/test_proof_tree.pl'], run_tests, halt" -s load.pl
```

## Architecture

![Proof tree construction and visualization for explainable AI reasoning](FIG_proof_trees.jpg)

## Description

Extends the meta-interpreter concept to build and display proof trees — a key capability for explainable AI. The `proof_tree.pl` module's `prove_with_tree/2` predicate traces each inference step, constructing a tree of `node/2`, `and/2`, and `leaf/1` terms. It handles user-defined clauses via `clause/2` lookup and built-in predicates (`\+/1`, `\=/2`) as explicit leaf nodes. The `print_proof/1` predicate pretty-prints this tree with Unicode box-drawing characters and indentation, showing exactly which rules and facts were used to derive a conclusion.