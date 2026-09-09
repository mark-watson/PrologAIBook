# Inference Engine

Forward and backward chaining inference engines with proof tree generation. Companion code for the Reasoning and Inference chapter.

## Running Examples

```shell
cd source-code/inference_engine
swipl -s load.pl
```

```prolog
?- add_fact(raining), add_rule([raining], wet_ground), forward_chain.
?- derived_fact(wet_ground).
```

## Running Tests

```shell
swipl -g "['tests/test_inference.pl'], run_tests, halt" -s load.pl
```


## Architecture

![Forward and backward chaining inference engines](FIG_inference_engine.jpg)

## Description

Implements two fundamental reasoning strategies in two separate modules, each with its own dynamic knowledge base. The `forward_chain.pl` module performs data-driven reasoning over its `fact/1` and `rule/2` predicates — it repeatedly applies rules whose conditions are satisfied by known facts, deriving new facts until no more can be produced (fixpoint); `reset_kb/0` clears its knowledge base. The `backward_chain.pl` module works goal-directed over its own `bc_fact/1` and `bc_rule/2` predicates, starting from a query and recursively trying to prove it via rules and facts, producing a proof tree that explains the reasoning chain; a visited-goal list makes cyclic rule sets fail rather than loop forever, and `reset_bc_kb/0` clears its knowledge base. Both modules use dynamic predicates for facts and rules, making them easy to load with different knowledge bases.
