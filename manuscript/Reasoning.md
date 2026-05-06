# Reasoning and Inference

Prolog is fundamentally a reasoning engine. In this chapter we explore how to use Prolog for various forms of logical reasoning that are central to AI.

{width: "80%"}
![Architecture diagram for the Inference Engine example](FIG_inference_engine.jpg)

{width: "80%"}
![Architecture diagram for the Proof Trees example](FIG_proof_trees.jpg)

{width: "80%"}
![Architecture diagram for the Medical Diagnosis example](FIG_medical_diagnosis.jpg)

## Propositional and First-Order Logic in Prolog

TBD: Expressing propositional and first-order logic statements as Prolog clauses. Understanding the relationship between Horn clauses and full first-order logic.

## Forward and Backward Chaining

TBD: Prolog's built-in backward chaining vs. implementing a forward-chaining inference engine. When to use each approach.

The **inference_engine** project implements a forward-chaining engine that derives new facts from rules until a fixpoint is reached. Here is the file **inference_engine/prolog/forward_chain.pl**:

```prolog
%% forward_chain.pl - Forward chaining inference engine
:- module(forward_chain, [
    forward_chain/0, add_rule/2, add_fact/1, derived_fact/1
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
%% backward_chain.pl - Backward chaining with explanation traces
:- module(backward_chain, [prove/2]).

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

## Reasoning with Uncertainty

TBD: Certainty factors and simple confidence scores attached to rules. Propagating confidence through inference chains.

## Abductive Reasoning

TBD: Generating explanations for observations. Implementing a simple abductive reasoning framework in Prolog.

## Non-Monotonic Reasoning and Defaults

TBD: Reasoning with incomplete information. Default logic, closed-world assumption, and negation as failure in practice.

## Case Study: A Medical Diagnosis Reasoner

TBD: A practical example combining multiple reasoning techniques to build a simple medical diagnosis system that explains its conclusions.

The **medical_diagnosis** project demonstrates rule-based diagnostic reasoning. Here is the file **medical_diagnosis/prolog/diagnosis.pl**:

```prolog
%% diagnosis.pl - Simple medical diagnosis reasoner
:- module(diagnosis, [diagnose/2, symptom/1]).

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
retract_symptoms([S|Rest]) :-
    retract(symptom(S)), retract_symptoms(Rest).

%% Disease knowledge base
disease(flu, [fever, cough, fatigue, body_aches]).
disease(cold, [sneezing, runny_nose, sore_throat]).
disease(allergy, [sneezing, itchy_eyes, runny_nose]).
disease(bronchitis,
    [cough, chest_pain, fatigue, shortness_of_breath]).
disease(migraine, [headache, nausea, light_sensitivity]).
```
