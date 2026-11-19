# Reasoning and Inference

Prolog is a reasoning engine at heart. In this chapter we use it for the main forms of logical reasoning in AI: forward and backward chaining, proof trees, reasoning with probabilities, abduction, and default reasoning.

## Propositional and First-Order Logic in Prolog

Prolog predicates map onto **First-Order Logic (FOL)**. Propositions become facts with no arguments, and predicates with variables express quantified statements.

#### Horn Clauses
Classical logic allows any mix of conjunction, disjunction, and negation, but proving arbitrary first-order formulas is costly. To stay efficient, Prolog limits its programs to **Horn clauses**.

A Horn clause is a disjunction of literals with *at most one positive (non-negated) literal*. In classical notation:
```$
A \lor \neg B_1 \lor \neg B_2 \lor \dots \lor \neg B_n
```

This is equivalent to the implication:
```$
(B_1 \land B_2 \land \dots \land B_n) \Rightarrow A
```

Prolog writes the implication with the conclusion first:
```prolog
A :- B1, B2, ..., Bn.
```
- **`A`** is the head (positive literal).
- **`B1, B2, ..., Bn`** form the body (the negative literals, joined by AND).
- A clause with no body is a **fact**.
- A clause with no head is a **query**. Prolog proves it by refutation: it shows that the negated query contradicts the program.

#### Mapping Logic to Prolog
Horn clauses run fast under **SLD resolution**, Prolog's proof method, but they limit what you can write directly:
- **Universal quantifiers (`\forall`$)**: Every variable in a clause is universally quantified.
- **Existential quantifiers (`\exists`$)**: A variable that appears only in the body acts as an existential. `has_child(X) :- parent(X, _).` means "X has a child if there is some Y such that X is a parent of Y".
- **Disjunction in the head**: Prolog does *not* allow heads like `A or B :- C.`. Disjunction in a body is fine: write several clauses with the same head, or use `;`.


{width: "80%"}
![Architecture diagram for the Inference Engine example](FIG_inference_engine.jpg)

## Forward and Backward Chaining

Logic systems apply rules to facts in two main ways:

#### Backward Chaining (Goal-Driven)
Backward chaining starts with a **goal** and works backward. It matches the goal against rule heads to find the subgoals that would prove it, and recurses until every subgoal matches a fact.
- **Prolog's default**: This is how Prolog runs every query.
- **When to use it**: When you have a specific goal and many facts, of which only a few matter to the goal.

#### Forward Chaining (Data-Driven)
Forward chaining starts with **known facts** and applies rules to derive new facts. It adds each new fact to the database and repeats until it reaches a *fixpoint*, where no rule can derive anything new.
- **When to use it**: When you want everything that follows from some starting data, as in configuration systems and event monitors.

The two approaches compare as follows:

| Feature | Backward Chaining | Forward Chaining |
| :--- | :--- | :--- |
| **Direction** | Goal `\to`$ Facts | Facts `\to`$ Conclusions |
| **In Prolog** | Built in | Needs extra code, as below |
| **Memory** | Low (stores only the current proof path) | Higher (stores every derived fact) |
| **Best Fit** | Diagnostic queries, verification | Event monitoring, data analysis |

The **inference_engine** project has a small forward-chaining engine. Rules are stored as `rule(Conditions, Conclusion)` facts, with the conditions in a list. Here is the file **inference_engine/prolog/forward_chain.pl**:

```prolog
%% forward_chain.pl - Forward chaining inference engine
%% Derives new facts from rules until no more can be derived
:- module(forward_chain, [
    forward_chain/0,
    add_rule/2,
    add_fact/1,
    derived_fact/1,
    reset_kb/0
]).

:- dynamic fact/1.
:- dynamic rule/2.

%% reset_kb - Remove all facts and rules from the knowledge base
reset_kb :-
    retractall(fact(_)),
    retractall(rule(_, _)).

%% add_fact(+Fact) - Assert Fact unless it is already known
add_fact(F) :-
    (   fact(F)
    ->  true
    ;   assertz(fact(F))
    ).

%% add_rule(+Conditions, +Conclusion)
add_rule(Conditions, Conclusion) :-
    assertz(rule(Conditions, Conclusion)).

%% derived_fact(?F) - Query derived facts
derived_fact(F) :- fact(F).

%% forward_chain - Apply all rules until fixpoint
%% Find one rule whose conditions hold and whose conclusion is new,
%% add the conclusion, and start over. When no rule fires, the
%% second clause succeeds: we have reached the fixpoint.
forward_chain :-
    rule(Conditions, Conclusion),
    all_conditions_met(Conditions),
    \+ fact(Conclusion),
    assertz(fact(Conclusion)),
    !,
    forward_chain.
forward_chain. % fixpoint reached

all_conditions_met([]).
all_conditions_met([C|Rest]) :-
    fact(C),
    all_conditions_met(Rest).
```

`reset_kb/0` clears the knowledge base so each run starts clean. Each pass through `forward_chain/0` fires one rule and then starts over from the first rule. This is simple but slow for large rule sets. Production rule engines such as those based on the Rete algorithm track which rules each new fact can affect.

```prolog
?- reset_kb, add_fact(raining),
   add_rule([raining], wet_ground),
   add_rule([wet_ground], slippery),
   forward_chain,
   findall(F, derived_fact(F), Facts).
Facts = [raining, wet_ground, slippery].
```

Prolog already chains backward, so why write a backward chainer? Because our own version can record *how* it proved each goal. Here is the file **inference_engine/prolog/backward_chain.pl**:

```prolog
%% backward_chain.pl - Backward chaining with explanation traces
%%
%% The internal prove/3 carries a visited-goals list so cyclic
%% rule sets terminate: a goal that is already on the current branch
%% of the proof search fails instead of looping forever.
:- module(backward_chain, [
    bc_fact/1,
    bc_rule/2,
    prove/2,
    reset_bc_kb/0
]).

:- dynamic bc_rule/2.
:- dynamic bc_fact/1.

%% reset_bc_kb - Remove all backward-chaining facts and rules
reset_bc_kb :-
    retractall(bc_fact(_)),
    retractall(bc_rule(_, _)).

%% prove(+Goal, -Proof) - Prove a goal and return the proof tree
prove(Goal, Proof) :-
    prove(Goal, Proof, []).

%% prove(+Goal, -Proof, +Visited) - Visited guards against cycles
prove(Goal, _, Visited) :-
    member(Goal, Visited),
    !,
    fail.
prove(Goal, fact(Goal), _) :-
    bc_fact(Goal).
prove(Goal, rule(Goal, Proofs), Visited) :-
    bc_rule(Conditions, Goal),
    prove_all(Conditions, Proofs, [Goal|Visited]).

prove_all([], [], _).
prove_all([C|Rest], [P|Proofs], Visited) :-
    prove(C, P, Visited),
    prove_all(Rest, Proofs, Visited).
```

`prove/2` returns a proof: `fact(G)` for a goal proved by a fact, and `rule(G, Proofs)` for a goal proved by a rule, with one proof per condition. It also carries a list of the goals on the current branch, so a cyclic rule set such as `a :- b` and `b :- a` fails instead of looping forever.

```prolog
?- reset_bc_kb,
   assertz(backward_chain:bc_fact(raining)),
   assertz(backward_chain:bc_rule([raining], wet_ground)),
   assertz(backward_chain:bc_rule([wet_ground], slippery)),
   prove(slippery, Proof).
Proof = rule(slippery, [rule(wet_ground, [fact(raining)])]) .
```

## Generating and Visualizing Proof Trees

Many AI applications, expert systems among them, must explain *why* they reached a conclusion. A **proof tree** records the rules and facts used to prove a goal.

The backward chainer above needs its rules in a special format. A **meta-interpreter**, a Prolog program that runs other Prolog programs, can build proof trees for ordinary Prolog code instead.


{width: "80%"}
![Architecture diagram for the Proof Trees example](FIG_proof_trees.jpg)


Here is the file **proof_trees/prolog/proof_tree.pl**:

```prolog
%% proof_tree.pl - Build and display proof trees
%% for explainable reasoning
:- module(proof_tree, [
    prove_with_tree/2,
    print_proof/1,
    sample_data_loaded/0
]).

%% sample_data_loaded
%% Load sample_data.pl from the directory that holds this file, so
%% the module works from any working directory. The clauses load
%% into this module, where clause/2 below can see them.
sample_data_loaded :-
    source_file(proof_tree:prove_with_tree(_, _), File),
    file_directory_name(File, Dir),
    directory_file_path(Dir, 'sample_data.pl', Data),
    consult(Data).

:- initialization(sample_data_loaded).

%% prove_with_tree(+Goal, -Tree) - Prove and return proof tree
prove_with_tree(true, leaf(true)) :- !.
prove_with_tree((A, B), and(PA, PB)) :- !,
    prove_with_tree(A, PA),
    prove_with_tree(B, PB).
%% Built-in predicates such as \+, \=, and is/2 have no clauses for
%% clause/2 to read, so we call them and record a leaf.
prove_with_tree(Goal, node(Goal, leaf(Goal))) :-
    predicate_property(Goal, built_in), !,
    call(Goal).
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

1. **Base case**: The goal `true` needs no proof and gives `leaf(true)`. A fact's body is `true`, so every fact ends in this leaf.
2. **Conjunctions**: For `(A, B)`, it proves `A` (giving tree `PA`) and then `B` (giving `PB`), and returns `and(PA, PB)`.
3. **Built-in predicates**: `predicate_property(Goal, built_in)` detects goals such as `\+ G`, `X \= Y`, and `X is E`. These have no clauses to read, so the interpreter calls them and records a leaf.
4. **User predicates**: `clause(Goal, Body)` finds a clause whose head unifies with `Goal` and returns its body. The interpreter recurses on the body. If several clauses match, backtracking tries each one, so the interpreter finds every proof that Prolog would find.

`sample_data_loaded/0` finds **sample_data.pl** next to the module's own file and loads it into the module, so the code works from any directory.

### Running the Proof Visualizer

The sample data holds a five-generation family tree with rules for `grandparent/2`, `ancestor/2`, `sibling/2`, `cousin/2`, and more:

```prolog
?- prove_with_tree(grandparent(adam, mary), Tree), print_proof(Tree).
├─ grandparent(adam,mary)
   ├─ parent(adam,john)
      ✓ true
   ├─ parent(john,mary)
      ✓ true
```

A proof that uses built-ins shows them as leaves. `make run` prints this proof that Carol and Emma are cousins:

```text
├─ cousin(carol,emma)
   ├─ grandparent(mary,carol)
      ├─ parent(mary,ann)
         ✓ true
      ├─ parent(ann,carol)
         ✓ true
   ├─ grandparent(mary,emma)
      ├─ parent(mary,bob)
         ✓ true
      ├─ parent(bob,emma)
         ✓ true
   ├─ carol\=emma
      ✓ carol\=emma
   ├─ \+sibling(carol,emma)
      ✓ \+sibling(carol,emma)
```

The Meta-Interpreters chapter extends this idea with depth bounds and other search strategies.

## Reasoning with Uncertainty

Real-world reasoning is rarely black and white. A simple way to handle uncertainty is to attach probabilities to facts and rules and multiply them along each chain of inference.

To compute the probability of a derived goal:
1. **Conjunction (AND)**: If a rule has several conditions, and we assume they are independent, the probability that all hold is the product of their probabilities:
   ```$
   P(A \land B) = P(A) \times P(B)
   ```
2. **Applying a rule**: The probability of the conclusion is the probability of the conditions times the rule's conditional probability:
   ```$
   P(Conclusion) = P(Conditions) \times P(Rule)
   ```

The **prob_reasoning** project implements this. Here is the query code from **prob_reasoning/prolog/prob_facts.pl**. The rest of the file, `load_example_kb/0`, asserts a weather knowledge base that the Probabilistic Logic Programming chapter walks through:

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
```

The module loads with an empty knowledge base. `load.pl` calls `load_example_kb/0`, which clears the knowledge base before asserting the example, so calling it twice does no harm.

The example says `cloudy` has probability 0.5 and `windy` 0.3, `rain` follows from `cloudy` with probability 0.8, and `storm` follows from `rain` and `windy` with probability 0.7:

```prolog
?- prob_query(storm, Prob).
Prob = 0.084.
```

That is `(0.5 \times 0.8) \times 0.3 \times 0.7 = 0.084`$. The independence assumption matters: if two conditions of a rule both depend on the same fact, multiplying their probabilities counts that fact twice and gives too low an answer. Also note that the cut after `prob_fact/2` means a stored probability overrides any rules for the same goal, and that a goal with two rules gives two answers rather than one combined probability. The Probabilistic Logic Programming chapter discusses better models.

## Abductive Reasoning

Abductive reasoning works from **observations** back to the **explanations** that could cause them. It is often called "inference to the best explanation".
- **Deduction**: Given `A`$ and `A \Rightarrow B`$, derive `B`$.
- **Induction**: Given examples of `A`$ and `B`$, derive the rule `A \Rightarrow B`$.
- **Abduction**: Given `B`$ and `A \Rightarrow B`$, hypothesize `A`$ as the explanation for `B`$.

In Prolog, we implement abduction by naming a set of **abducibles**: goals we may assume true if they help explain an observation. Here is the file **inference_engine/prolog/abduction.pl**, a meta-interpreter in the same style as `prove_with_tree/2`:

```prolog
%% abduction.pl - Abductive reasoning with a meta-interpreter
:- module(abduction, [
    abduce/3,
    explanations/3
]).

%% abduce(+Goal, +Abducibles, -Explanation)
%% Explanation is a list of abducible goals that, if assumed true,
%% prove Goal. Backtracking yields other explanations. Goal is
%% module-sensitive, so rules are found in the caller's module.
:- meta_predicate abduce(:, +, -), explanations(:, +, -).

abduce(M:Goal, Abducibles, Expl) :-
    abduce(Goal, M, Abducibles, Expl).

abduce(true, _, _, []) :- !.
abduce((A, B), M, Abducibles, Expl) :- !,
    abduce(A, M, Abducibles, ExplA),
    abduce(B, M, Abducibles, ExplB),
    append(ExplA, ExplB, Expl).
abduce(Goal, _, Abducibles, [Goal]) :-
    memberchk(Goal, Abducibles).
abduce(Goal, M, Abducibles, Expl) :-
    \+ memberchk(Goal, Abducibles),
    clause(M:Goal, Body),
    abduce(Body, M, Abducibles, Expl).

%% explanations(+Goal, +Abducibles, -Sets)
%% Sets holds every distinct explanation, each sorted, smallest
%% first.
explanations(Goal, Abducibles, Sets) :-
    findall(Set,
            ( abduce(Goal, Abducibles, Expl), sort(Expl, Set) ),
            All),
    sort(All, Unique),
    map_list_to_pairs(length, Unique, Keyed),
    keysort(Keyed, Sorted),
    pairs_values(Sorted, Sets).

%% Example domain. The abducibles have no clauses: they are causes
%% we may assume, not facts we know. Load this file with
%% use_module/1 and query abduction:grass_is_wet, or copy these
%% rules into your own module.
:- dynamic rained/0, sprinkler_was_on/0, pipe_burst/0.

grass_is_wet :- rained.
grass_is_wet :- sprinkler_was_on.
street_is_wet :- rained.
street_is_wet :- pipe_burst.
```

When `abduce/4` meets an abducible, it adds the goal to the explanation instead of trying to prove it. Otherwise it reads the goal's clauses as `prove_with_tree/2` does. The `meta_predicate` declaration makes `abduce/3` look up rules in the caller's module, so it works on rules you define in your own code.

With the example rules, wet grass has two explanations:

```prolog
?- abduce(abduction:grass_is_wet, [rained, sprinkler_was_on], E).
E = [rained] ;
E = [sprinkler_was_on].
```

Which explanation is *best*? A common choice is the smallest one. `explanations/3` collects every explanation, removes duplicates, and sorts them by size. If both the grass and the street are wet, one cause explains both:

```prolog
?- explanations((abduction:grass_is_wet, abduction:street_is_wet),
                [rained, sprinkler_was_on, pipe_burst], Sets).
Sets = [[rained], [pipe_burst, rained], [pipe_burst, sprinkler_was_on],
        [rained, sprinkler_was_on]].
```

## Non-Monotonic Reasoning and Defaults

Classical logic is **monotonic**: adding facts never removes a conclusion. Human reasoning is often **non-monotonic**: we draw default conclusions and drop them when we learn something new.

Prolog gets non-monotonic behavior from the **Closed World Assumption** and **Negation as Failure** (`\+`). A **default rule** holds unless we can prove an exception.

#### Default Logic Example
The classic example: "Birds fly, unless they are abnormal (like penguins or ostriches)." Here is the file **inference_engine/prolog/defaults.pl**:

```prolog
%% defaults.pl - Default reasoning with negation as failure
:- module(defaults, [
    flies/1,
    bird/1,
    learn/1,
    forget/1
]).

%% penguin/1 and ostrich/1 are dynamic so that a query such as
%% flies(tweety) fails cleanly when no such facts exist, and so
%% that learn/1 can add them later.
:- dynamic penguin/1, ostrich/1, bird/1.

%% Birds fly by default, unless we can prove they are abnormal.
flies(X) :-
    bird(X),
    \+ abnormal(X).

abnormal(X) :- penguin(X).
abnormal(X) :- ostrich(X).

bird(tweety).
bird(pingu).
penguin(pingu).

%% learn(+Fact) and forget(+Fact) change what we know.
learn(Fact) :- assertz(Fact).
forget(Fact) :- retract(Fact).
```

- `?- flies(tweety).` succeeds: `bird(tweety)` is true and Prolog cannot prove `abnormal(tweety)`.
- `?- flies(pingu).` fails: `penguin(pingu)` proves `abnormal(pingu)`, so `\+ abnormal(pingu)` fails.

The `dynamic` declaration matters. Without it, `abnormal(tweety)` would call `ostrich/1`, which has no clauses, and Prolog would raise an existence error instead of failing. Declaring the predicate dynamic tells Prolog that having no clauses is fine.

Now suppose we learn that Tweety is a penguin too:

```prolog
?- flies(tweety).
true.

?- learn(defaults:penguin(tweety)).
true.

?- flies(tweety).
false.
```

Adding a fact removed a conclusion, which classical logic never allows.

## Case Study: A Medical Diagnosis Reasoner

Our last example is a small **medical diagnosis reasoner** that matches a patient's symptoms against a disease knowledge base and explains its answer. (It is a teaching example, not medical advice.)

`diagnose/2` checks whether a disease's required symptoms are a `subset/2` of the patient's symptoms and formats an explanation. Real patients rarely show every symptom, so `rank_diagnoses/2` scores each disease by the fraction of its symptoms the patient has, and lists the matched and missing symptoms. The code asserts nothing, so repeated calls give the same answers.


{width: "80%"}
![Architecture diagram for the Medical Diagnosis example](FIG_medical_diagnosis.jpg)

Here is the file **medical_diagnosis/prolog/diagnosis.pl**:

```prolog
%% diagnosis.pl - Simple medical diagnosis reasoner
%% Demonstrates reasoning with multiple rules and explanation
%%
%% This implementation is a pure function of the input symptom list:
%% it matches the patient's symptoms against the disease knowledge base
%% using subset/2 without asserting or retracting any dynamic state.

:- module(diagnosis, [
    diagnose/2,
    rank_diagnoses/2
]).

%% diagnose(+PatientSymptoms, -DiagnosisWithExplanation)
%% Pure list-based matching: succeeds iff some disease's required
%% symptoms are a subset of the patient's symptoms.
diagnose(Symptoms, diagnosis(Disease, Explanation)) :-
    disease(Disease, RequiredSymptoms),
    subset(RequiredSymptoms, Symptoms),
    format(atom(Explanation),
           'Diagnosis: ~w based on symptoms: ~w',
           [Disease, RequiredSymptoms]).

%% rank_diagnoses(+PatientSymptoms, -Ranked)
%% Ranked is a list of match(Score, Disease, Matched, Missing) terms,
%% best first, for every disease that shares at least one symptom
%% with the patient. Score is the fraction of the disease's symptoms
%% that the patient has, rounded to two places.
rank_diagnoses(Symptoms, Ranked) :-
    findall(match(Score, Disease, Matched, Missing),
            (   disease(Disease, Required),
                intersection(Required, Symptoms, Matched),
                Matched \== [],
                subtract(Required, Symptoms, Missing),
                length(Matched, M),
                length(Required, R),
                Score is round(100 * M / R) / 100.0
            ),
            Matches),
    sort(1, @>=, Matches, Ranked).

%% Disease knowledge base
disease(flu, [fever, cough, fatigue, body_aches]).
disease(cold, [sneezing, runny_nose, sore_throat]).
disease(allergy, [sneezing, itchy_eyes, runny_nose]).
disease(bronchitis, [cough, chest_pain, fatigue, shortness_of_breath]).
disease(migraine, [headache, nausea, light_sensitivity]).
```

Here is the output of `make run`:

```text
Diagnosis 1: diagnosis(flu,Diagnosis: flu based on symptoms: [fever,cough,fatigue,body_aches])
Diagnosis 2: diagnosis(cold,Diagnosis: cold based on symptoms: [sneezing,runny_nose,sore_throat])
Ranked for [cough, fatigue, fever]:
  match(0.75,flu,[fever,cough,fatigue],[body_aches])
  match(0.5,bronchitis,[cough,fatigue],[chest_pain,shortness_of_breath])
```

The patient in the last query has three of the four flu symptoms. `diagnose/2` finds nothing for them, but `rank_diagnoses/2` suggests flu first and shows that asking about body aches would settle it. The missing symptoms are the questions an expert system would ask next, which leads into the next chapter.

## Optional Practice Problems

1. **Ruling Out Diseases**: In `medical_diagnosis`, add `excludes(Disease, Symptom)` facts (for example, allergies do not cause fever) and change `rank_diagnoses/2` to drop a disease when the patient has a symptom that excludes it.
2. **Combining Rules**: In `prob_reasoning`, `prob_query/2` returns one answer per rule when two rules conclude the same goal. Write `prob_combined/2`, which combines the answers with the noisy-OR formula `1 - (1 - P_1)(1 - P_2)`$.
3. **Proof Trees for Abduction**: Change `abduce/3` so it returns a proof tree along with the explanation, marking each assumed goal as `assumed(Goal)`.
