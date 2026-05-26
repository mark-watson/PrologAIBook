# Probabilistic Logic Programming

Probabilistic logic programming combines the expressiveness of Prolog with the ability to reason under uncertainty. SWI-Prolog supports several probabilistic programming frameworks that are highly relevant for modern AI applications. We look at a simple example in this chapter and then take a more general look at probability in the next chapter.

{width: "80%"}
![Architecture diagram for the Probabilistic Reasoning example](FIG_prob_reasoning.jpg)

## Why Probabilistic Reasoning?

In classical logic, a statement is either true or false. This binary worldview works well for pure mathematics but fails in real-world AI applications where information is almost always incomplete, noisy, or uncertain.

Classical Prolog relies on the **Closed World Assumption**: if a fact cannot be proven true from the knowledge base, it is assumed to be false. However, in the real world, a lack of evidence does not equal evidence of absence. Furthermore, classical logic is **monotonic**: once a fact is proven, it remains true regardless of any new information added to the system. 

In contrast, real-world reasoning is **non-monotonic** and probabilistic. For instance, we might believe a patient has a specific illness with $90\%$ certainty, but when a new test result comes back negative, our belief should adapt. Probabilistic logic programming solves this by representing truth values as real numbers in the range $[0, 1]$, representing the probability or degree of belief that a statement holds. This allows us to build logic models that handle exceptions, noisy measurements, and uncertain outcomes.

## ProbLog and Probabilistic Facts

One of the most popular frameworks for combining logic with probability is **ProbLog**. In ProbLog, facts can be annotated with their probability of being true:
```prolog
0.3::windy.
0.5::cloudy.
```
This notation declares that `windy` has a $30\%$ chance of being true, and `cloudy` has a $50\%$ chance. Under the **distribution semantics** introduced by Taisuke Sato, a ProbLog program defines a probability distribution over a set of possible worlds. In each possible world, every probabilistic fact is independently chosen to be either true (with probability $p$) or false (with probability $1-p$). The probability of a query is the sum of the probabilities of all possible worlds in which the query can be logically proven.

While a full ProbLog solver requires compiling queries into Binary Decision Diagrams (BDDs) to handle dependencies and logical cycles, we can implement a lightweight reasoner using certainty factors in pure Prolog. This approach propagates probabilities recursively through backtracking search.

The **prob_reasoning** project implements a lightweight probabilistic reasoner. Here is the file **prob_reasoning/prolog/prob_facts.pl**:

```prolog
%% prob_facts.pl - Probabilistic reasoning with certainty factors
%% A lightweight implementation without external pack dependencies
:- module(prob_facts, [
    prob_fact/2,
    prob_rule/3,
    prob_query/2
]).

:- dynamic prob_fact/2.  % prob_fact(Fact, Probability)

%% prob_rule(+Conditions, +Conclusion, +CondProb)
%% If all Conditions hold, conclude Conclusion with conditional
%% probability
:- dynamic prob_rule/3.

%% prob_query(+Goal, -Probability)
%% Query the probability of a goal given known facts and rules
prob_query(Goal, Prob) :-
    prob_fact(Goal, Prob), !.
prob_query(Goal, Prob) :-
    prob_rule(Conditions, Goal, CondProb),
    maplist(prob_query, Conditions, CondProbs),
    foldl(mul, CondProbs, 1.0, JointProb),
    Prob is JointProb * CondProb.

mul(X, Acc, Result) :- Result is Acc * X.

%% Example knowledge base (simple)
:- assert(prob_fact(cloudy, 0.5)).
:- assert(prob_fact(windy, 0.3)).
:- assert(prob_rule([cloudy], rain, 0.8)).
:- assert(prob_rule([rain, windy], storm, 0.7)).

%% Complex weather knowledge base
%% 5 base facts, 7 rules, 4 levels of reasoning depth
%% Chain: low_pressure -> unstable_air -> thick_clouds -> severe_storm
%% -> tornado_risk
%%        cold_front + warm_front -> frontal_zone -> storm_system ->
%%        severe_storm -> flash_flood_risk
%% Probabilities:
%%   P(unstable_air)      = 0.5*0.8                       = 0.4
%%   P(thick_clouds)      = 0.5*0.4*0.5                   = 0.1
%%   P(frontal_zone)      = 0.5*0.5*0.6                   = 0.15
%%   P(storm_system)      = 0.15*0.5*0.8                  = 0.06
%%   P(severe_storm)      = 0.1*0.06*0.5                  = 0.003
%%   P(tornado_risk)      = 0.003*0.6                     = 0.0018
%%   P(flash_flood_risk)  = 0.003*0.8                     = 0.0024
:- assert(prob_fact(low_pressure, 0.5)).
:- assert(prob_fact(high_humidity, 0.5)).
:- assert(prob_fact(cold_front, 0.5)).
:- assert(prob_fact(warm_front, 0.5)).
:- assert(prob_fact(jet_stream_dip, 0.5)).
:- assert(prob_rule([low_pressure], unstable_air, 0.8)).
:- assert(prob_rule([high_humidity, unstable_air], thick_clouds, 0.5)).
:- assert(prob_rule([cold_front, warm_front], frontal_zone, 0.6)).
:- assert(prob_rule([frontal_zone, jet_stream_dip], storm_system, 0.8)).
:- assert(prob_rule([thick_clouds, storm_system], severe_storm, 0.5)).
:- assert(prob_rule([severe_storm], tornado_risk, 0.6)).
:- assert(prob_rule([severe_storm], flash_flood_risk, 0.8)).
```

#### How the Reasoner Works
- **Facts and Rules**: The reasoner defines probabilistic facts using `prob_fact(Fact, Probability)` and conditional rules using `prob_rule(Conditions, Goal, CondProb)`.
- **Query Propagation**: The `prob_query/2` predicate calculates the probability of a goal:
  1. If the goal matches a base fact directly, it returns that probability.
  2. If the goal is derived via a rule, it recursively calls `prob_query/2` on all conditions in the rule's body using `maplist/3`.
  3. It then multiplies all the condition probabilities together using `foldl/4` and the `mul/3` helper to compute the `JointProb` of the preconditions.
  4. Finally, the joint probability is multiplied by the rule's conditional probability (`CondProb`) to get the final goal probability.

#### Deep Probability Attenuation
The weather knowledge base demonstrates how probabilities attenuate (rapidly decrease) across deep inference chains. Consider the path from `low_pressure` to `tornado_risk`:
1. `low_pressure` is a base fact with $P=0.5$.
2. `unstable_air` is derived from `low_pressure` with conditional probability $0.8$, yielding $P=0.5 \times 0.8 = 0.4$.
3. `thick_clouds` is derived from `high_humidity` ($P=0.5$) and `unstable_air` ($P=0.4$) with conditional probability $0.5$, yielding $P=0.5 \times 0.4 \times 0.5 = 0.1$.
4. Parallel reasoning yields `frontal_zone` ($P=0.15$) and `storm_system` ($P=0.06$).
5. `severe_storm` converges from `thick_clouds` and `storm_system` with conditional probability $0.5$, yielding $P=0.1 \times 0.06 \times 0.5 = 0.003$.
6. `tornado_risk` is derived from `severe_storm` with conditional probability $0.6$, yielding $P=0.003 \times 0.6 = 0.0018$.

This rapid attenuation shows that naive multiplication across deep chains can quickly shrink probabilities. In real-world applications, to prevent underflow and model complex dependencies correctly, we use more sophisticated models like Bayesian networks or full ProbLog.

## Learning Probabilities from Data

Writing down exact probability values for every fact and rule is difficult. In practice, we often have the logical structure of the model but need to learn the probability values from experimental data or observations.

This process is called **parameter learning** (implemented in ProbLog as LFI, or *Learning from Interpretations*). The learning system is given:
1. A logic program containing facts and rules with unknown probability parameters.
2. A database of training interpretations (examples of observed states, which may be complete or incomplete).

Under the hood, the system uses the **Expectation-Maximization (EM)** algorithm:
- **Expectation Step (E-step)**: Using the current probability estimates, the system computes the expected truth values of all unobserved (latent) variables in the training data.
- **Maximization Step (M-step)**: The system updates the probability parameters to maximize the likelihood of both the observed and expected data.

This iterative process continues until the parameters converge, allowing us to train probabilistic logic systems directly from tabular data, sensor logs, or historical records.

## Bayesian Networks in Prolog

A **Bayesian Network** is a directed acyclic graph (DAG) where nodes represent random variables and edges represent conditional dependencies. Each node is associated with a Conditional Probability Table (CPT) expressing the probability of the node given the states of its parent nodes.

Prolog is well-suited for representing Bayesian networks. We can represent the network structure and CPTs directly as facts:

```prolog
% network_structure: parent(ParentNode, ChildNode)
parent(cloudy, rain).
parent(cloudy, sprinkler).
parent(rain, wet_grass).
parent(sprinkler, wet_grass).

% CPT entries: cpt(Node, State, ParentStates, Probability)
cpt(cloudy, true, [], 0.5).
cpt(sprinkler, true, [cloudy=true], 0.1).
cpt(sprinkler, true, [cloudy=false], 0.5).
cpt(rain, true, [cloudy=true], 0.8).
cpt(rain, true, [cloudy=false], 0.2).

% wet_grass depends on both rain and sprinkler
cpt(wet_grass, true, [sprinkler=true, rain=true], 0.99).
cpt(wet_grass, true, [sprinkler=true, rain=false], 0.90).
cpt(wet_grass, true, [sprinkler=false, rain=true], 0.90).
cpt(wet_grass, true, [sprinkler=false, rain=false], 0.01).
```

To perform inference (such as calculating $P(\text{rain} \mid \text{wet\_grass} = \text{true})$), we can write a query solver that uses **variable elimination** or **enumeration** to sum out the latent variables over the joint distribution:

$$P(A \mid B) = \frac{P(A, B)}{P(B)} = \frac{\sum_{Y} P(A, B, Y)}{\sum_{X, Y} P(X, B, Y)}$$

Prolog's pattern matching and list processing make it easy to traverse parent-child relationships and lookup CPT probabilities during joint probability factorization.

## Practical Applications

Probabilistic logic programming has several unique strengths for real-world AI systems:

1. **Fault Diagnosis under Uncertainty**:
   Industrial systems contain many interconnected components. When a sensor reports a failure, we must diagnose the root cause. Since sensors are noisy and can fail themselves, probabilistic logic allows us to model rules like *"If component X fails, sensor Y shows error with 95% probability, but sensor Y has a 2% random failure rate."* The inference engine can then identify the most likely failed component.

2. **Medical Reasoning**:
   Diseases and symptoms do not have a simple one-to-one mapping. A symptom can be caused by multiple diseases, and a disease does not always produce all symptoms. By modeling symptoms as probabilistic facts and diseases as conditional hypotheses, we can calculate the posterior probability of each diagnosis given a patient's clinical file.

3. **Information Extraction Pipelines**:
   Modern NLP systems (like NER taggers or relation extractors) output extracted facts with confidence scores. By feeding these confidence scores directly into a probabilistic Prolog reasoner as probabilistic facts (e.g., `0.85::extracted_relation('ACME', 'acquired', 'BetaCorp')`), we can run logical reasoning while correctly propagating the extraction uncertainty downstream to final conclusions.

