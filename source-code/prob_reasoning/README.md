# Probabilistic Reasoning

Lightweight probabilistic reasoning with certainty factor propagation. Companion code for the Probabilistic Logic Programming chapter.

## Running Examples

```shell
cd source-code/prob_reasoning
swipl -s load.pl
```

```prolog
?- prob_query(cloudy, P).
?- prob_query(rain, P).
?- prob_query(storm, P).
```

## Running Tests

```shell
swipl -g "['tests/test_prob.pl'], run_tests, halt" -s load.pl
```


## Architecture

![Probabilistic reasoning with certainty factors and Bayesian probability chains](FIG_prob_reasoning.jpg)

## Description

Implements a simple probabilistic reasoning system without external pack dependencies. Facts are annotated with probabilities (`prob_fact/2`), and rules specify conditional probabilities (`prob_rule/3`). The `prob_query/2` predicate computes the probability of a goal by multiplying the probabilities along the inference chain. This provides an accessible introduction to reasoning under uncertainty before moving to more sophisticated frameworks like ProbLog or cplint. The example knowledge base models weather relationships: cloudy → rain → storm.
