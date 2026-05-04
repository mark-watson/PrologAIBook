# Meta-Interpreters

Vanilla and bounded-depth meta-interpreters — Prolog interpreting Prolog. Companion code for the Meta-Interpreters chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- assert((likes(john, mary) :- true)).
?- mi_solve(likes(john, mary)).
?- mi_bounded(likes(john, mary), 5).
```

## Running Tests

```shell
swipl -g "load_test_files([]), run_tests, halt" -s load.pl
```

## Description

Meta-interpreters are uniquely Prolog — a program that interprets Prolog programs within Prolog itself. The `vanilla.pl` module implements the classic three-clause meta-interpreter and a variant that builds proof trees. The `bounded.pl` module adds a depth limit to prevent infinite recursion, which is essential for reasoning over potentially cyclic knowledge bases. These patterns are the foundation for building custom search strategies, explanation facilities, and debugging tools.
