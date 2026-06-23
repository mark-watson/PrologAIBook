# Reasoning and Inference

Prolog is fundamentally a reasoning engine. In this chapter we explore how to use Prolog for various forms of logical reasoning that are central to AI.

## Propositional and First-Order Logic in Prolog

Prolog predicates naturally map to **First-Order Logic (FOL)**. We express propositional variables as simple arity-0 facts, and relational predicates with variables to represent quantified logical statements.

#### Horn Clauses
Classical logic allows rules with arbitrary conjunctions, disjunctions, and negations. However, resolving arbitrary first-order formulas is computationally expensive. To remain efficient, Prolog restricts its database to **Horn clauses**.

A Horn clause is a disjunction of literals with *at most one positive (non-negated) literal*. In classical notation:
{$$}
A \lor \neg B_1 \lor \neg B_2 \lor \dots \lor \neg B_n
{/$$}

By applying Boolean algebra, this is logically equivalent to the implication:
{$$}
(B_1 \land B_2 \land \dots \land B_n) \Rightarrow A
{/$$}

In Prolog, this implication is written in reverse as:
```prolog
A :- B1, B2, ..., Bn.
```
- **`A`** is the head (positive literal).
- **`B1, B2, ..., Bn`** make up the body (conjunctive negative literals).
- If there is no body, the clause is a **fact** (equivalent to a positive literal asserting truth).
- If there is no head, the clause represents a **query** (a goal to be disproven via contradiction).

#### Mapping Logic to Prolog
While this Horn clause format is highly efficient for execution using **SLD Resolution**, it does place some limitations on what can be directly expressed:
- **Universal Quantifiers (`\forall`$)**: Implicitly assumed for all variables in a rule.
- **Existential Quantifiers (`\exists`$)**: Represented by introducing new variables on the right-hand side of a rule (e.g. `has_child(X) :- parent(X, _).` means "For all X, X has a child if there exists some Y such that X is a parent of Y").
- **Disjunction in the Head**: Prolog does *not* allow disjunctive heads like `A or B :- C.`. You must split this into multiple rules, or use helper predicates.


{width: "80%"}
![Architecture diagram for the Inference Engine example](FIG_inference_engine.jpg)

## Forward and Backward Chaining

In logic systems, we use two main strategies to apply rules to facts:

#### Backward Chaining (Goal-Driven)
Backward chaining starts with a **goal** (query) and works backward, matching it against rule heads to find the subgoals (body conditions) needed to prove it. This recursion continues until all subgoals are resolved by direct facts in the database.
- **Prolog's Default**: This is Prolog's built-in execution strategy.
- **When to Use**: Best when you have a specific goal to prove and a large number of facts, but only a small subset are relevant to the query.

#### Forward Chaining (Data-Driven)
Forward chaining starts with **known facts** and applies rules to derive new facts. These new facts are asserted into the database, and the process repeats until a *fixpoint* is reached (i.e., no more new facts can be derived).
- **When to Use**: Best when you want to discover everything that follows from a set of starting data, such as in configuration systems, event monitors, or scheduling pipelines.

Here is a comparison of the two approaches:

| Feature | Backward Chaining | Forward Chaining |
| :--- | :--- | :--- |
| **Direction** | Goal `\to`$ Facts | Facts `\to`$ Conclusions |
| **Prolog Integration** | Native execution engine | Needs custom meta-interpreter |
| **Space Complexity** | Low (only stores active path in stack) | High (asserts all derived facts on heap) |
| **Best Fit** | Diagnostic queries, verification | Event monitoring, data analysis |

The **inference_engine** project implements a forward-chaining engine that derives new facts from rules until a fixpoint is reached. Here is the file **inference_engine/prolog/forward_chain.pl**:

```prolog
%% forward_chain.pl - Forward chaining inference engine
%% Derives new facts from rules until no more can be derived
:- module(forward_chain, [
    forward_chain/0,
    add_rule/2,
    add_fact/1,
    derived_fact/1
]).

:- dynamic fact/1.
:- dynamic rule/2.

%% add_fact(+Fact) - Assert a new fact
add_fact(F) :- \+ fact(F), assert(fact(F)).
add_fact(_).

%% add_rule(+Conditions, +Conclusion)
add_rule(Conditions, Conclusion) :-
    assert(rule(Conditions, Conclusion)).

%% derived_fact(?F) - Query derived facts
derived_fact(F) :- fact(F).

%% forward_chain - Apply all rules until fixpoint
forward_chain :-
    rule(Conditions, Conclusion),
    \+ fact(Conclusion),
    all_conditions_met(Conditions),
    assert(fact(Conclusion)),
    !,
    forward_chain.
forward_chain. % fixpoint reached

all_conditions_met([]).
all_conditions_met([C|Rest]) :-
    fact(C),
    all_conditions_met(Rest).
```

And a backward-chaining engine with explanation traces. Here is the file **inference_engine/prolog/backward_chain.pl**:

```prolog
:- module(backward_chain, [
    prove/2
]).

:- dynamic bc_rule/2.
:- dynamic bc_fact/1.

%% prove(+Goal, -Proof) - Prove a goal and return the proof tree
prove(Goal, fact(Goal)) :-
    bc_fact(Goal).
prove(Goal, rule(Goal, Proofs)) :-
    bc_rule(Conditions, Goal),
    prove_all(Conditions, Proofs).

prove_all([], []).
prove_all([C|Rest], [P|Proofs]) :-
    prove(C, P),
    prove_all(Rest, Proofs).

```

## Generating and Visualizing Proof Trees

While deriving conclusions is useful, in many AI applications (such as expert systems) we must also explain *why* a conclusion was reached. A **proof tree** is a tree-like data structure that records the steps, rules, and facts used to satisfy a goal.

Prolog is well-suited for building proof trees because we can easily write a **meta-interpreter**—a Prolog program that reads and executes other Prolog programs.


{width: "80%"}
![Architecture diagram for the Proof Trees example](FIG_proof_trees.jpg)


The companion project **proof_trees** demonstrates this technique. Here is the core file **proof_trees/prolog/proof_tree.pl**:

```prolog
%% proof_tree.pl - Build and display proof trees
%% for explainable reasoning
:- module(proof_tree, [
    prove_with_tree/2,
    print_proof/1,
    sample_data_loaded/0
]).

sample_data_loaded :-
    (   exists_file('sample_data.pl')
    ->  consult('sample_data.pl')
    ;   exists_file('prolog/sample_data.pl')
    ->  consult('prolog/sample_data.pl')
    ;   format(user_error, 'WARNING: sample_data.pl not found~n', []),
        fail
    ).

:- initialization(sample_data_loaded).

%% prove_with_tree(+Goal, -Tree) - Prove and return proof tree
prove_with_tree(true, leaf(true)) :- !.
prove_with_tree((A, B), and(PA, PB)) :- !,
    prove_with_tree(A, PA),
    prove_with_tree(B, PB).
%% Handle negation-as-failure (meta-builtin)
prove_with_tree(\+ G, node(\+ G, leaf(\+ G))) :- !,
    \+ G.
%% Handle not-unifiable (builtin comparison)
prove_with_tree(X \= Y, node(X\=Y, leaf(X\=Y))) :- !,
    X \= Y.
%% User-defined goals: look up clauses and recurse
prove_with_tree(Goal, node(Goal, ChildProofs)) :-
    clause(Goal, Body),
    prove_with_tree(Body, ChildProofs).

%% print_proof(+Tree) - Pretty-print a proof tree with indentation
print_proof(Tree) :- print_proof(Tree, 0).

print_proof(leaf(true), Indent) :- !,
    tab(Indent), format("✓ true~n").
print_proof(leaf(Goal), Indent) :-
    tab(Indent), format("✓ ~w~n", [Goal]).
print_proof(and(A, B), Indent) :-
    print_proof(A, Indent),
    print_proof(B, Indent).
print_proof(node(Goal, Children), Indent) :-
    tab(Indent), format("├─ ~w~n", [Goal]),
    Indent1 is Indent + 3,
    print_proof(Children, Indent1).
```

### How the Meta-Interpreter Works

1. **Base Cases**: When the goal is `true`, it is trivially proven and returns `leaf(true)`.
2. **Conjunctions**: For a goal composed of `(A, B)`, it recursively proves `A` (producing proof tree `PA`) and `B` (producing `PB`), and returns `and(PA, PB)`.
3. **Built-in Handling**: Special handlers are defined for negation-as-failure (`\+ G`) and inequality checks (`X \= Y`).
4. **Clause Inspection**: For user-defined predicates, `clause(Goal, Body)` is a built-in Prolog feature that inspects the database, finding a rule whose head matches `Goal` and returning its `Body`. The interpreter then recurses on the `Body` to find child proofs.

### Running the Proof Visualizer

If we query the sample family relationships database:

```prolog
?- prove_with_tree(grandparent(adam, mary), Tree), print_proof(Tree).
├─ grandparent(adam, mary)
   ├─ parent(adam, john)
      ✓ true
   ├─ parent(john, mary)
      ✓ true
```
This gives us a readable, tree-structured explanation of the system's reasoning process.
```

## Reasoning with Uncertainty

In real-world applications, reasoning is rarely black-and-white. AI systems must often handle uncertain or probabilistic information. One classic approach to this is attaching **certainty factors** or probabilities to rules and facts, and propagating those scores through the inference chain.

To compute the probability of a derived goal, we apply the rules of probability:
1. **Conjunction (AND)**: If a rule depends on multiple conditions, the probability of the conditions holding jointly is the product of their individual probabilities (assuming independence):
   {$$}
   P(A \land B) = P(A) \times P(B)
   {/$$}
2. **Rule Application**: The probability of the conclusion is the joint probability of its conditions multiplied by the conditional probability (confidence) of the rule:
   {$$}
   P(Conclusion) = P(Conditions) \times P(Rule)
   {/$$}

The companion project **prob_reasoning** implements this logic. Here is the complete file **prob_reasoning/prolog/prob_facts.pl**:

```prolog
%% prob_facts.pl - Probabilistic reasoning with certainty factors
:- module(prob_facts, [
    prob_fact/2,
    prob_rule/3,
    prob_query/2
]).

:- dynamic prob_fact/2.  % prob_fact(Fact, Probability)
:- dynamic prob_rule/3;  % prob_rule(Conditions, Conclusion, CondProb)

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
```

If we query the weather database defined in this project:

```prolog
?- prob_query(storm, Prob).
Prob = 0.105.
```
```

## Abductive Reasoning

Abductive reasoning is the process of reasoning from **observations** to the most likely **explanations** (or hypotheses) that could cause them. It is often described as "inference to the best explanation."
- **Deduction**: Given `A`$ and `A \Rightarrow B`$, derive `B`$.
- **Induction**: Given examples of `A`$ and `B`$, derive the rule `A \Rightarrow B`$.
- **Abduction**: Given `B`$ and `A \Rightarrow B`$, hypothesize `A`$ as the explanation for `B`$.

In Prolog, we can implement abductive reasoning by defining a set of **abducible predicates**—facts that we are allowed to assume true if they help explain the observation.

Here is a simple abductive meta-interpreter:

```prolog
%% abduce(+Goal, +Abducibles, -Explanation)
%% Finds a set of abducible assumptions that prove Goal
abduce(true, _, []) :- !.
abduce((A, B), Abducibles, Expl) :- !,
    abduce(A, Abducibles, ExplA),
    abduce(B, Abducibles, ExplB),
    append(ExplA, ExplB, Expl).
abduce(Goal, Abducibles, [Goal]) :-
    member(Goal, Abducibles).
abduce(Goal, Abducibles, Expl) :-
    clause(Goal, Body),
    abduce(Body, Abducibles, Expl).
```

If we define the rules:
```prolog
grass_is_wet :- rained.
grass_is_wet :- sprinkler_was_on.
```
And declare `[rained, sprinkler_was_on]` as our list of abducibles, calling `abduce(grass_is_wet, [rained, sprinkler_was_on], Expl)` will backtrack to yield two possible explanations: `[rained]` or `[sprinkler_was_on]`.

## Non-Monotonic Reasoning and Defaults

Classical logic is **monotonic**: once a conclusion is proven true, adding new facts to the database can never invalidate it. However, human reasoning is often **non-monotonic**: we draw default conclusions that we retract when we receive new, contradictory information.

Prolog implements non-monotonic reasoning using the **Closed-World Assumption** and **Negation as Failure** (`\+`). We can write **default rules** that hold true unless an exception is proven.

#### Default Logic Example
A classic example is reasoning about bird flight: "Birds fly by default, unless they are abnormal (like penguins or ostriches)."

```prolog
flies(X) :-
    bird(X),
    \+ abnormal(X).

abnormal(X) :- penguin(X).
abnormal(X) :- ostrich(X).

bird(tweety).
bird(pingu).
penguin(pingu).
```

If we query the database:
- `?- flies(tweety).` succeeds because `bird(tweety)` is true and `abnormal(tweety)` cannot be proven (fails).
- `?- flies(pingu).` fails because `penguin(pingu)` is asserted, which proves `abnormal(pingu)`, thereby causing `\+ abnormal(pingu)` to fail.

If we later learn that Tweety is actually a penguin and assert `penguin(tweety).`, the previous conclusion `flies(tweety)` is automatically retracted—demonstrating non-monotonic behavior.

## Case Study: A Medical Diagnosis Reasoner

To see how these reasoning techniques come together, we can look at a practical case study: a **Medical Diagnosis Reasoner**. This system diagnoses diseases by matching patient symptoms against a clinical knowledge base and generating an explicit explanation.

The companion project **medical_diagnosis** implements this diagnostic reasoner. The program uses a clean rule-matching approach:
1. It accepts a list of patient symptoms and asserts them dynamically into the database.
2. It queries the disease knowledge base to find a disease whose required symptoms are a subset of the patient's symptoms.
3. It formats a diagnostic explanation.
4. It cleans up the temporary asserted facts to prevent side effects in subsequent runs.


{width: "80%"}
![Architecture diagram for the Medical Diagnosis example](FIG_medical_diagnosis.jpg)

The **medical_diagnosis** project demonstrates rule-based diagnostic reasoning. Here is the file **medical_diagnosis/prolog/diagnosis.pl**:

```prolog
:- module(diagnosis, [
    diagnose/2,
    symptom/1
]).

:- dynamic symptom/1.

%% diagnose(+PatientSymptoms, -DiagnosisWithExplanation)
diagnose(Symptoms, diagnosis(Disease, Explanation)) :-
    maplist(assert_symptom, Symptoms),
    disease(Disease, RequiredSymptoms),
    subset(RequiredSymptoms, Symptoms),
    format(atom(Explanation),
           'Diagnosis: ~w based on symptoms: ~w',
           [Disease, RequiredSymptoms]),
    retract_symptoms(Symptoms).

assert_symptom(S) :- assert(symptom(S)).
retract_symptoms([]).
retract_symptoms([S|Rest]) :- retract(symptom(S)),
    retract_symptoms(Rest).

%% Disease knowledge base
disease(flu, [fever, cough, fatigue, body_aches]).
disease(cold, [sneezing, runny_nose, sore_throat]).
disease(allergy, [sneezing, itchy_eyes, runny_nose]).
disease(bronchitis, [cough, chest_pain, fatigue, shortness_of_breath]).
disease(migraine, [headache, nausea, light_sensitivity]).
```

Here is sample output:

TBD

## Optional Practice Problems

1. **Extended Diagnosis Rules**: In the `medical_diagnosis` project, add rules for diagnosing a new condition (e.g., flu or allergy) based on symptom overlap, and ensure that conflicting symptoms are handled gracefully.
2. **Structured Proof Tree Printing**: In `proof_trees`, write a helper predicate to print the generated proof tree using visual indentation levels (e.g., nested bullet points) rather than raw Prolog terms.
