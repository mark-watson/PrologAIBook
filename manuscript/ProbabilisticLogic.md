# Probabilistic Logic Programming

Probabilistic logic programming adds reasoning under uncertainty to Prolog. In this chapter we build two small reasoners in plain Prolog: one that multiplies probabilities along rule chains, and one that does exact inference in a Bayesian network. The next chapter takes a broader look at probability.

{width: "80%"}
![Architecture diagram for the Probabilistic Reasoning example](FIG_prob_reasoning.jpg)

## Why Probabilistic Reasoning?

In classical logic, a statement is true or false. That works for mathematics, but in AI applications our information is usually incomplete, noisy, or uncertain.

Prolog uses the **Closed World Assumption**: anything it cannot prove, it treats as false. In the real world, a lack of evidence is not evidence of absence.

Real reasoning also revises its beliefs. We might believe a patient has an illness with `90\%`$ certainty, then lower that belief when a test comes back negative. Probabilistic logic programming attaches a probability in `[0, 1]`$ to each fact, so a program can weigh uncertain evidence and update its conclusions.

## ProbLog and Probabilistic Facts

**ProbLog** is a popular language that combines logic with probability. In ProbLog, each fact can carry the probability that it is true:
```prolog
0.3::windy.
0.5::cloudy.
```
This says `windy` is true with probability `0.3`$ and `cloudy` with probability `0.5`$. Under the **distribution semantics** of Taisuke Sato, a ProbLog program defines a probability distribution over *possible worlds*. In each world, every probabilistic fact is independently true (with probability `p`$) or false (with probability `1-p`$). The probability of a query is the total probability of the worlds in which Prolog can prove it.

A full ProbLog system compiles queries into Binary Decision Diagrams (BDDs) to handle facts that several proofs share. ProbLog itself is a Python system; for SWI-Prolog, the `cplint` pack offers similar languages. Here we write a much simpler reasoner in plain Prolog that multiplies probabilities along each chain of rules, assuming the conditions of each rule are independent.

Here is the file **prob_reasoning/prolog/prob_facts.pl**:

```prolog
%% prob_facts.pl - Probabilistic reasoning over annotated facts/rules
%%
%% NOTE: the code multiplies probabilities along the inference
%% chain, assuming the conditions of a rule are independent. It is
%% NOT MYCIN-style certainty-factor combination.
%%
%% Product chains are computed in log space (a foldl of the log of each
%% factor, then exp/1 of the sum) so that deep chains do not underflow
%% to 0.0 in floating point.
%%
%% prob_query/3 carries a visited-goal list so that cyclic rule bases
%% terminate: a goal already on the current reasoning branch fails
%% instead of looping forever.
%%
%% The dynamic facts and rules are empty at module load; call
%% load_example_kb/0 (see load.pl) to populate the weather example.

:- module(prob_facts, [
    prob_fact/2,
    prob_rule/3,
    prob_query/2,
    load_example_kb/0
]).

:- dynamic prob_fact/2.  % prob_fact(Fact, Probability)

%% prob_rule(+Conditions, +Conclusion, +CondProb)
%% If all Conditions hold, conclude Conclusion with conditional
%% probability
:- dynamic prob_rule/3.

%% prob_query(+Goal, -Probability)
%% Query the probability of a goal given known facts and rules
prob_query(Goal, Prob) :-
    prob_query(Goal, Prob, []).

%% prob_query(+Goal, -Probability, +Visited) - Visited guards cycles
prob_query(Goal, _, Visited) :-
    member(Goal, Visited),
    !,
    fail.
prob_query(Goal, Prob, _) :-
    prob_fact(Goal, Prob), !.
prob_query(Goal, Prob, Visited) :-
    prob_rule(Conditions, Goal, CondProb),
    maplist(prob_query_([Goal|Visited]), Conditions, CondProbs),
    foldl(sum_log, CondProbs, 0.0, LogJoint),
    Prob is exp(LogJoint) * CondProb.

%% Bridge for maplist so Visited is threaded into recursive calls
prob_query_(Visited, Goal, Prob) :-
    prob_query(Goal, Prob, Visited).

%% sum_log(+P, +Acc, -Result)
%% Accumulate log probabilities; P =:= 0.0 contributes -inf.
sum_log(P, Acc, Result) :-
    (   P =:= 0.0
    ->  Result = -inf
    ;   Result is Acc + log(P)
    ).

%% load_example_kb - Assert the weather example knowledge base.
%% Idempotent: retracts any existing KB first, so it is safe to call
%% repeatedly (e.g. on reload).
load_example_kb :-
    retractall(prob_fact(_, _)),
    retractall(prob_rule(_, _, _)),
    assertz(prob_fact(cloudy, 0.5)),
    assertz(prob_fact(windy, 0.3)),
    assertz(prob_rule([cloudy], rain, 0.8)),
    assertz(prob_rule([rain, windy], storm, 0.7)),
    %% Complex weather knowledge base
    %% 5 base facts, 7 rules, 4 levels of reasoning depth
    %% Chain: low_pressure -> unstable_air -> thick_clouds ->
    %% severe_storm -> tornado_risk
    %%        cold_front + warm_front -> frontal_zone -> storm_system
    %%        -> severe_storm -> flash_flood_risk
    %% Probabilities:
    %%   P(unstable_air)      = 0.5*0.8                   = 0.4
    %%   P(thick_clouds)      = 0.5*0.4*0.5               = 0.1
    %%   P(frontal_zone)      = 0.5*0.5*0.6               = 0.15
    %%   P(storm_system)      = 0.15*0.5*0.8              = 0.06
    %%   P(severe_storm)      = 0.1*0.06*0.5              = 0.003
    %%   P(tornado_risk)      = 0.003*0.6                 = 0.0018
    %%   P(flash_flood_risk)  = 0.003*0.8                 = 0.0024
    assertz(prob_fact(low_pressure, 0.5)),
    assertz(prob_fact(high_humidity, 0.5)),
    assertz(prob_fact(cold_front, 0.5)),
    assertz(prob_fact(warm_front, 0.5)),
    assertz(prob_fact(jet_stream_dip, 0.5)),
    assertz(prob_rule([low_pressure], unstable_air, 0.8)),
    assertz(prob_rule([high_humidity, unstable_air], thick_clouds, 0.5)),
    assertz(prob_rule([cold_front, warm_front], frontal_zone, 0.6)),
    assertz(prob_rule([frontal_zone, jet_stream_dip], storm_system, 0.8)),
    assertz(prob_rule([thick_clouds, storm_system], severe_storm, 0.5)),
    assertz(prob_rule([severe_storm], tornado_risk, 0.6)),
    assertz(prob_rule([severe_storm], flash_flood_risk, 0.8)).
```

#### How the Reasoner Works
- **Facts and Rules**: The reasoner defines probabilistic facts using `prob_fact(Fact, Probability)` and conditional rules using `prob_rule(Conditions, Goal, CondProb)`.
- **Query Propagation**: The `prob_query/2` predicate calculates the probability of a goal:
  1. If the goal matches a base fact directly, it returns that probability.
  2. If the goal is derived via a rule, it recursively calls `prob_query/2` on all conditions in the rule's body using `maplist/3`.
  3. It then multiplies all the condition probabilities together using `foldl/4` over the log of each condition probability (the `sum_log/3` helper), so the joint is a log-space sum. Computing in log space avoids floating-point underflow on deep chains.
  4. Finally, the log joint is converted back with `exp/1` and multiplied by the rule's conditional probability (`CondProb`) to get the final goal probability.

#### Deep Probability Attenuation
The weather knowledge base demonstrates how probabilities attenuate (rapidly decrease) across deep inference chains. Consider the path from `low_pressure` to `tornado_risk`:
1. `low_pressure` is a base fact with `P=0.5`$.
2. `unstable_air` is derived from `low_pressure` with conditional probability `0.8`$, yielding `P=0.5 \times 0.8 = 0.4`$.
3. `thick_clouds` is derived from `high_humidity` (`P=0.5`$) and `unstable_air` (`P=0.4`$) with conditional probability `0.5`$, yielding `P=0.5 \times 0.4 \times 0.5 = 0.1`$.
4. Parallel reasoning yields `frontal_zone` (`P=0.15`$) and `storm_system` (`P=0.06`$).
5. `severe_storm` converges from `thick_clouds` and `storm_system` with conditional probability `0.5`$, yielding `P=0.1 \times 0.06 \times 0.5 = 0.003`$.
6. `tornado_risk` is derived from `severe_storm` with conditional probability `0.6`$, yielding `P=0.003 \times 0.6 = 0.0018`$.

Multiplying along deep chains shrinks probabilities fast. Computing the products in log space keeps very small values from underflowing to zero. The model also has limits: it assumes independence, and it cannot reason from effects back to causes. A Bayesian network handles both, as the next sections show.

## Learning Probabilities from Data

This section gives background only; the book's code does not include a learner.

Writing down exact probabilities for every fact and rule is hard. Often we know the structure of a model but must learn its probabilities from data.

This is **parameter learning** (in ProbLog, LFI, or *Learning from Interpretations*). The learner is given:
1. A logic program containing facts and rules with unknown probability parameters.
2. A database of training interpretations (examples of observed states, which may be complete or incomplete).

It uses the **Expectation-Maximization (EM)** algorithm:
- **E-step**: With the current estimates, compute the expected truth values of the variables the data does not show.
- **M-step**: Update the probabilities to maximize the likelihood of the observed data together with those expected values.

The two steps repeat until the probabilities stop changing. When the data shows every variable, no EM is needed: each CPT entry is just a ratio of counts, which you could compute in Prolog with `aggregate_all/3`.

## Bayesian Networks in Prolog

A **Bayesian network** is a directed acyclic graph whose nodes are random variables and whose edges show direct dependence. Each node has a Conditional Probability Table (CPT) that gives its probability for each combination of its parents' values.

The network gives the probability of a complete *world*, an assignment of a value to every variable, as a product of one CPT entry per node:

```$
P(x_1, \dots, x_n) = \prod_i P(x_i \mid \mathrm{parents}(x_i))
```

From that, we can answer any conditional query by summing worlds:

```$
P(A \mid B) = \frac{P(A, B)}{P(B)} = \frac{\sum_{\text{worlds with } A, B} P(w)}{\sum_{\text{worlds with } B} P(w)}
```

Here is the classic sprinkler network: clouds make rain more likely and the sprinkler less likely, and either rain or the sprinkler wets the grass. The file **prob_reasoning/prolog/bayes_net.pl** stores the network as facts and answers queries by enumerating all worlds:

```prolog
%% bayes_net.pl - Exact inference in a small Bayesian network by
%% enumerating all possible worlds.
:- module(bayes_net, [
    prob/3,
    joint/2,
    world/1
]).

%% Network structure: parent(ParentNode, ChildNode)
parent(cloudy, rain).
parent(cloudy, sprinkler).
parent(rain, wet_grass).
parent(sprinkler, wet_grass).

%% CPT entries: cpt(Node, true, ParentStates, Probability)
%% gives P(Node = true | ParentStates). P(Node = false | ...) is
%% 1 minus that value.
cpt(cloudy, true, [], 0.5).
cpt(sprinkler, true, [cloudy=true], 0.1).
cpt(sprinkler, true, [cloudy=false], 0.5).
cpt(rain, true, [cloudy=true], 0.8).
cpt(rain, true, [cloudy=false], 0.2).
cpt(wet_grass, true, [sprinkler=true, rain=true], 0.99).
cpt(wet_grass, true, [sprinkler=true, rain=false], 0.90).
cpt(wet_grass, true, [sprinkler=false, rain=true], 0.90).
cpt(wet_grass, true, [sprinkler=false, rain=false], 0.01).

%% The network's variables. Every node appears in some cpt/4 fact.
variables(Vars) :-
    findall(V, cpt(V, _, _, _), Vs),
    sort(Vs, Vars).

%% world(-World)
%% World is a list Var=Value giving every variable a value. On
%% backtracking it enumerates all 2^N worlds.
world(World) :-
    variables(Vars),
    maplist(assign, Vars, World).

assign(Var, Var=Value) :-
    member(Value, [true, false]).

%% joint(+World, -P)
%% The probability of a complete world: the product of
%% P(node | parents) over all nodes (the chain rule for Bayes nets).
joint(World, P) :-
    foldl(node_factor(World), World, 1.0, P).

node_factor(World, Node=Value, P0, P) :-
    cpt(Node, true, ParentStates, PTrue),
    subset(ParentStates, World),
    !,
    (   Value == true
    ->  P is P0 * PTrue
    ;   P is P0 * (1 - PTrue)
    ).

%% prob(+Query, +Evidence, -P)
%% P is P(Query | Evidence), where Query and Evidence are lists of
%% Var=Value. We sum the joint probability of the worlds where
%% Query and Evidence hold, and divide by the sum over the worlds
%% where Evidence holds.
prob(Query, Evidence, P) :-
    append(Query, Evidence, Both),
    mass(Both, PBoth),
    mass(Evidence, PEvidence),
    PEvidence > 0,
    P is PBoth / PEvidence.

%% mass(+Partial, -P): total probability of the worlds that agree
%% with the partial assignment Partial.
mass(Partial, P) :-
    aggregate_all(sum(PW),
                  ( world(W), subset(Partial, W), joint(W, PW) ),
                  P).
```

`world/1` generates assignments on backtracking, and `joint/2` multiplies one CPT entry per node. `node_factor/4` finds the right CPT row with `subset/2`, so the parent states in a `cpt/4` fact can be listed in any order. `prob/3` sums the matching worlds with `aggregate_all/3`.

```prolog
?- prob([rain=true], [wet_grass=true], P).
P = 0.7047692307692307.

?- prob([rain=true], [wet_grass=true, sprinkler=true], P).
P = 0.32038834951456313.
```

Wet grass raises the probability of rain from 0.5 to about 0.70. But if we also learn that the sprinkler was on, the probability of rain drops to about 0.32: the sprinkler *explains away* the wet grass. The weather reasoner earlier in this chapter cannot do this, because it only pushes probabilities forward from causes to effects.

Enumeration takes time exponential in the number of variables (here 2 to the power 4, or 16 worlds). Real systems use variable elimination or compile the network into a BDD, as ProbLog does, but they compute the same numbers.

## Practical Applications

Probabilistic logic programming suits these kinds of AI systems:

1. **Fault Diagnosis under Uncertainty**:
   Industrial systems have many connected parts. When a sensor reports a failure, we must find the cause, and sensors can fail too. Probabilistic logic can model rules like *"If component X fails, sensor Y shows an error with 95% probability, but sensor Y also fails at random 2% of the time."* Inference then finds the most likely failed part, just as `prob/3` reasons from wet grass back to rain.

2. **Medical Reasoning**:
   A symptom can have several causes, and a disease does not always show every symptom. A network with diseases as parents and symptoms as children gives the probability of each diagnosis given the patient's symptoms.

3. **Information Extraction Pipelines**:
   NLP systems such as entity and relation extractors give each extracted fact a confidence score. Loading the scores as probabilistic facts (e.g., `0.85::extracted_relation('ACME', 'acquired', 'BetaCorp')`) lets later reasoning carry the extraction uncertainty through to its conclusions.


## Optional Practice Problems

1. **Flight Delays**: Add a `snow` fact with probability 0.3 and a rule that snow delays a flight with probability 0.8 to `load_example_kb/0`. What is the probability that the flight is *on time*? (Hint: `prob_query/2` gives the probability of a delay caused by snow.)
2. **Coin Flips as Possible Worlds**: Make a copy of `bayes_net.pl` with three independent coins, each a node with no parents and `P(heads) = 0.6`$. Use `world/1` and `joint/2` to compute the probability of at least two heads. Check your answer by hand.
3. **A Fourth Cause**: Add a `dew` node with no parents to the sprinkler network and make it a parent of `wet_grass`. How does `P(rain | wet_grass)` change?
