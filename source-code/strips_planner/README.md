# STRIPS Planner

Classical AI planning with STRIPS-style preconditions and effects. Companion code for the Planning and Scheduling chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- plan([on_table(a), clear(a), hand_empty], [holding(a)], Plan).
?- plan([on_table(a), on_table(b), clear(a), clear(b), hand_empty],
        [on(a, b)], Plan).
```

## Running Tests

```shell
swipl -g "['tests/test_strips.pl'], run_tests, halt" -s load.pl
```


## Architecture

![STRIPS-style planner with action schemas and state-space search](FIG_strips_planner.jpg)

## Description

Implements the STRIPS planning algorithm where actions are defined by preconditions, add lists, and delete lists. The `plan/3` predicate searches for a sequence of actions that transforms the initial state into one satisfying the goal conditions. The included block manipulation operators (pickup, putdown, stack, unstack) form a complete blocks world action set. Prolog's backtracking provides the search mechanism, making the planner concise and easy to extend with new domains.
