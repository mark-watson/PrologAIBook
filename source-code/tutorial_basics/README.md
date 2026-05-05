# Tutorial Basics

Fundamental Prolog examples covering facts, rules, queries, unification, backtracking, and list processing. This is the companion code for the Prolog Tutorial chapter.

## Running Examples

```shell
cd source-code/tutorial_basics
swipl -s load.pl
```

Then try queries in the REPL:

```prolog
?- parent(tom, bob).
?- grandparent(tom, ann).
?- sibling(ann, pat).
?- my_reverse([1,2,3], R).
```

## Running Tests

```shell
swipl -g "['tests/test_family.pl', 'tests/test_lists.pl'], run_tests, halt" -s load.pl
```


## Architecture

![Tutorial basics showing family relationships and list operation modules](FIG_tutorial_basics.jpg)

## Description

The `family.pl` module demonstrates core Prolog concepts through family relationships — defining facts (`parent/2`), building rules (`grandparent/2`, `sibling/2`, `ancestor/2`), and querying them with backtracking. The `lists.pl` module implements classic list operations (`length`, `member`, `append`, `reverse`, `last`) from scratch using recursion and pattern matching, showing how Prolog's head/tail list decomposition works.
