# Reactive Agent

A goal-directed AI agent framework with perception-reasoning-action loop. Companion code for the Building AI Agents chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- define_goal(answer_found).
?- register_tool(search, search_web/1).
?- run_agent(10).
```

## Running Tests

```shell
swipl -g "load_test_files([]), run_tests, halt" -s load.pl
```

## Description

Provides a reusable agent framework with a perceive→reason→act loop. Agents have goals, beliefs, and registered tools. The `run_agent/1` predicate runs the loop for a maximum number of steps, checking if the goal is achieved after each cycle. Actions are logged with timestamps. The framework is designed to be extended with domain-specific perception, action selection, and tool execution predicates.
