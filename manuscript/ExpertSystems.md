# Expert Systems and Rule-Based AI

Expert systems were one of the earliest commercial successes of AI, and Prolog is an ideal language for building them. In this chapter we build a complete expert system shell and demonstrate it with practical examples.

{width: "80%"}
![Architecture diagram for the Expert Shell example](FIG_expert_shell.jpg)

## What Is an Expert System?

An **expert system** is a computer program that emulates the decision-making ability of a human expert. Developed in the 1970s and 1980s during the "Rule-Based AI" era (producing famous systems like MYCIN and DENDRAL), they represent one of the first successful applications of AI to real-world problems.

The standard architecture of an expert system consists of four key components:
1. **Knowledge Base (KB)**: A database of domain-specific facts and rules (heuristic knowledge) usually structured as "IF-THEN" statements.
2. **Inference Engine**: The brain of the system, which applies logical rules to the knowledge base to deduce new information or prove a hypothesis. It can operate via forward chaining (data-driven) or backward chaining (goal-driven).
3. **Explanation Facility**: A module that explains the system's reasoning path to the user, answering "How" a conclusion was reached or "Why" a particular question is being asked.
4. **User Interface**: The interactive portal through which the system prompts the user for missing information and displays conclusions.

Prolog is uniquely suited for building expert systems because its core runtime environment already includes an inference engine (SLD resolution) and a backtracking search mechanism.

## Building an Expert System Shell in Prolog

Instead of hard-coding an expert system for a single domain, we can build a **domain-independent shell**. The shell defines the interactive loop, maintains the database of user-supplied facts, and provides explanation utilities, while the specific domain knowledge is loaded from a separate rules file via the shell's `load_kb/1` predicate.

To implement the shell, we use Prolog's dynamic database to store facts provided by the user during a session using `known/2` terms. Prolog's built-in backward-chaining engine automatically executes the rules. When a rule needs an attribute that is not yet known, the shell prompts the user, records the answer, and continues evaluation.

The **expert_shell** project provides a domain-independent shell. Here is the file **expert_shell/prolog/shell.pl**:

```prolog
 %% shell.pl - Expert system shell with backward chaining and explanations
:- module(shell, [
    consult_expert/1,
    explain/1,
    ask_question/1,
    provide_answer/2,
    reset_known/0,
    load_kb/1
]).

:- dynamic known/2.  % known(Attribute, Value) - user-provided facts

%% reset_known - Clear all user-provided answers
reset_known :-
    retractall(known(_, _)).

%% provide_answer(+Attribute, +Value)
%% Programmatically supply an answer (used by tests and non-interactive
%% drivers) instead of prompting the user.
provide_answer(Attribute, Value) :-
    retractall(known(Attribute, _)),
    assertz(known(Attribute, Value)).

%% consult_expert(-Conclusion) - Main entry point
%% When a KB has been loaded via load_kb/1, its hypothesis/1 rules
%% (in module user) are tried first; otherwise the built-in default
%% applies.  Answers provided earlier via provide_answer/2 are kept;
%% call reset_known/0 explicitly for a fresh consultation.
consult_expert(Conclusion) :-
    consult_kb_hypothesis(Conclusion),
    !.

consult_kb_hypothesis(Conclusion) :-
    kb_file(_),
    !,
    user:hypothesis(Conclusion).
consult_kb_hypothesis(Conclusion) :-
    hypothesis(Conclusion).

%% explain(+Conclusion) - Show reasoning chain
explain(Conclusion) :-
    explanation_text(Conclusion, Explanation),
    format("Conclusion: ~w~n", [Conclusion]),
    format("Reasoning: ~w~n", [Explanation]).

explanation_text(C, E) :-
    kb_file(_),
    user:hypothesis_explanation(C, E),
    !.
explanation_text(C, E) :-
    hypothesis_explanation(C, E).

%% ask_question(+Attribute) - Ask user for information
%% Reuse a known answer; otherwise read a line, strip a trailing '.',
%% and convert to an atom or number as appropriate.  EOF aborts the
%% consultation gracefully.
ask_question(Attribute) :-
    known(Attribute, Value),
    !,
    format("~w: (cached) ~w~n", [Attribute, Value]).
ask_question(Attribute) :-
    format("~nWhat is the value of ~w? ", [Attribute]),
    catch(read_line_to_string(user_input, Line),
          _, Line = end_of_file),
    (   Line == end_of_file
    ->  format("~nEOF reached; aborting consultation.~n"),
        fail
    ;   normalize_answer(Line, Value),
        provide_answer(Attribute, Value)
    ).

%% normalize_answer(+RawString, -Value)
%% Strip a trailing '.', try a numeric conversion, else produce an atom.
normalize_answer(Raw, Value) :-
    string_codes(Raw, Codes0),
    strip_trailing_dot(Codes0, Codes),
    string_codes(Term, Codes),
    (   catch(atom_number(Term, Value), _, fail)
    ->  true
    ;   atom_string(Value, Term)
    ).

strip_trailing_dot(Codes, Rest) :-
    append(Rest, [0'.], Codes),
    !.
strip_trailing_dot(Codes, Codes).

%% load_kb(+File) - Consult a knowledge-base file defining hypothesis/1
%% and hypothesis_explanation/2 rules (if_/then_ style conditions read
%% known/2 answers via check/1).  Clears previously loaded KB rules.
:- dynamic kb_file/1.

load_kb(File) :-
    retractall(kb_file(_)),
    unload_old_kb,
    assertz(kb_file(File)),
    open(File, read, In),
    repeat,
      read(In, Term),
      (   Term == end_of_file
      ->  close(In), !
      ;   assertz(user:Term),
          fail
      ).

unload_old_kb :-
    forall(clause(user:hypothesis(_), _, Ref), erase(Ref)),
    forall(clause(user:hypothesis_explanation(_, _), _, Ref),
           erase(Ref)),
    dynamic(user:hypothesis/1),
    dynamic(user:hypothesis_explanation/2).

%% check(+Condition) - True when the attribute has been answered as
%% requested, prompting via ask_question/1 when not yet known.
check(A == V) :- !,
    (   known(A, V)
    ->  true
    ;   \+ known(A, _),
        ask_question(A),
        known(A, V)
    ).

%% Default hypothesis rules (used when no KB is loaded)
hypothesis(unknown) :-
    format("Could not determine a conclusion from the given facts.~n").

hypothesis_explanation(
    unknown,
    'Insufficient data to reach a conclusion.').
```

The shell's key predicates:

- **`consult_expert/1`** is the main entry point. It tries the loaded KB's `hypothesis/1` rules first (falling back to the built-in `unknown` hypothesis) and no longer auto-retracts `known/2` facts. Call `reset_known/0` explicitly for a fresh consultation.
- **`explain/1`** routes through `explanation_text/2`, preferring the loaded KB's `hypothesis_explanation/2` over the shell's own default.
- **`ask_question/1`** reads a line with `read_line_to_string/2`, runs `normalize_answer/2` (which strips a trailing `.` and converts numbers) and treats EOF as a graceful abort. Known answers are reused and printed as "(cached)".
- **`provide_answer/2`** supplies an answer programmatically (used by tests and non-interactive drivers) instead of prompting.
- **`reset_known/0`** clears all user-provided answers.
- **`load_kb/1`** loads a user knowledge-base file and asserts its `hypothesis/1` and `hypothesis_explanation/2` clauses into module `user`, clearing any previously loaded KB rules. This is what makes pluggable knowledge bases real rather than aspirational.

## Knowledge Acquisition and Rule Representation

**Knowledge acquisition** is the process of extracting domain knowledge from human experts and structuring it into rules. In a Prolog-based expert system, we represent this knowledge using clauses.

#### Structuring Rules for the Shell
To plug into our shell, a domain knowledge base must define rules for the `hypothesis/1` predicate and explanations for `hypothesis_explanation/2`.
To prompt the user interactively, we define an `ask_if/2` helper:

```prolog
ask_if(Attribute, Value) :-
    known(Attribute, Value), !.
ask_if(Attribute, Value) :-
    \+ known(Attribute, _),
    ask_question(Attribute),
    known(Attribute, Value).
```

A rule in the knowledge base then looks like this:
```prolog
hypothesis(diagnose_internet_issue) :-
    ask_if(router_lights, off),
    ask_if(cables_plugged_in, yes).
```

#### Improving Readability with Custom Operators
To make rules more readable for non-programmers, Prolog allows you to define custom **operators** using `op/3`. For example, we can define operators like `if`, `then`, `and`, and `is` to write rules in a natural-language-like syntax:

```prolog
:- op(900, xfx, then).
:- op(800, xfy, and).
:- op(700, xfx, is).

% Now we can write rules like:
% rule 1: if router_lights is off and cables are connected then problem is router_power.
```
We can then write a simple parser/meta-interpreter to evaluate these custom-cased rules.

## Explanation Facilities

One of the defining features of an expert system is its ability to explain its reasoning.
- **"How" Explanations**: Explain how the system reached a specific conclusion. This is done by traversing the proof tree or rule firing history and listing the rules and facts that succeeded.
- **"Why" Explanations**: Explain why the system is asking a particular question. When the system prompts the user with a question, the user can type `why`. The system responds by showing the current rule it is trying to satisfy and the subgoal chain.

In our simplified `shell.pl` implementation, we provide a basic "How" explanation via `explain/1`, which fetches the pre-written `hypothesis_explanation/2` text associated with the successful hypothesis. In a more advanced system, we can integrate the proof-tree meta-interpreter (from the previous chapter) to dynamically construct and display step-by-step explanations.

## Case Study: A Wine Selection Advisor

To demonstrate rule-based reasoning in a practical domain, we look at the **wine_advisor** project. This advisor acts as a digital sommelier, recommending wines by matching food pairings and flavor profiles.

The system utilizes two distinct categories of rules:
1. **Meal Pairing Rules**: Determining which color of wine (red, white, rose) matches the food type (fish, red meat, dessert).
2. **Flavor Preference Rules**: Matching the user's preference with the wine's characteristics. The preference may be a body atom (`bold`, `moderate`, `light`) or a sweetness atom (`sweet`, `dry`).

{width: "80%"}
![Architecture diagram for the Wine Advisor example](FIG_wine_advisor.jpg)

The **wine_advisor** project implements a rule-based wine recommender. Here is the file **wine_advisor/prolog/wine_rules.pl**:

```prolog
 %% wine_rules.pl - Wine selection expert system
:- module(wine_rules, [
    recommend_wine/3
]).

%% recommend_wine(+MealType, +Preference, -Wine)
%% Preference may be a body atom (bold, moderate, light), a sweetness
%% atom (sweet, dry), or 'any' matching all wines on both dimensions.
recommend_wine(MealType, Preference, Wine) :-
    wine(Wine, Color, Body, Sweetness),
    meal_pairs_with(MealType, Color),
    preference_matches(Preference, Body),
    sweetness_matches(Preference, Sweetness).

%% Wine database: wine(Name, Color, Body, Sweetness)
wine(cabernet_sauvignon, red, full, dry).
wine(merlot, red, medium, dry).
wine(pinot_noir, red, light, dry).
wine(chardonnay, white, full, dry).
wine(sauvignon_blanc, white, light, dry).
wine(riesling, white, light, sweet).
wine(champagne, white, light, dry).
wine(rose, rose, light, dry).
wine(port, red, full, sweet).

%% Meal pairing rules
meal_pairs_with(red_meat, red).
meal_pairs_with(poultry, red).
meal_pairs_with(poultry, white).
meal_pairs_with(fish, white).
meal_pairs_with(seafood, white).
meal_pairs_with(pasta, red).
meal_pairs_with(dessert, white).
meal_pairs_with(cheese, red).

%% Preference matching: body dimension.
%% Sweetness preferences (sweet, dry) do not constrain body.
preference_matches(bold, full).
preference_matches(moderate, medium).
preference_matches(light, light).
preference_matches(sweet, _).
preference_matches(dry, _).
preference_matches(any, _).

%% Sweetness matching.
%% Body preferences (bold, moderate, light) do not constrain sweetness.
sweetness_matches(sweet, sweet).
sweetness_matches(dry, dry).
sweetness_matches(bold, _).
sweetness_matches(moderate, _).
sweetness_matches(light, _).
sweetness_matches(any, _).
```

This is a behavior change from the first edition of this chapter: body and sweetness are now orthogonal dimensions. `recommend_wine(red_meat, bold, W)` returns both `cabernet_sauvignon` and `port` because a `bold` preference constrains only body, not sweetness, and `port` is a full-bodied red. `recommend_wine(dessert, sweet, W)` returns only `[riesling]` because `dessert` pairs with white wine and only `riesling` is both white and sweet.

## Case Study: A Pluggable Knowledge Base

As a final case study, we use the shell's `load_kb/1` support with the bundled **expert_shell/prolog/sample_kb.pl**, a small wine-selection knowledge base. Four hypotheses (serve_port, serve_riesling, serve_cabernet, serve_sauvignon_blanc) are driven by `shell:check/1` conditions that read `known/2` answers or prompt the user:

```prolog
 %% sample_kb.pl - Wine-selection knowledge base for expert_shell
 %%
 %% If_/then_ style hypotheses: each condition is checked via
 %% shell:check/1, which reuses known/2 answers or asks the user.
 %% shell:load_kb/1 asserts these clauses into module `user` so the
 %% shell can find them via user:hypothesis/1 and
 %% user:hypothesis_explanation/2.

hypothesis(serve_port) :-
    shell:check(meal == dessert),
    shell:check(sweet_preference == yes).

hypothesis(serve_riesling) :-
    shell:check(sweet_preference == yes),
    \+ shell:known(meal, dessert).

hypothesis(serve_cabernet) :-
    shell:check(meal == red_meat),
    shell:check(bold_preference == yes).

hypothesis(serve_sauvignon_blanc) :-
    shell:check(meal == fish),
    shell:check(light_preference == yes).

hypothesis_explanation(serve_port,
    'A dessert meal plus a sweet preference points to port.').
hypothesis_explanation(serve_riesling,
    'A sweet preference without a dessert meal suggests riesling.').
hypothesis_explanation(serve_cabernet,
    'Red meat plus a bold preference points to cabernet sauvignon.').
hypothesis_explanation(serve_sauvignon_blanc,
    'Fish plus a light preference points to sauvignon blanc.').
```

### Running the Wine Knowledge Base

Load the KB and run a consultation in the SWI-Prolog REPL. Here we supply the answers programmatically with `provide_answer/2`:

```prolog
?- shell:load_kb('prolog/sample_kb.pl'),
   shell:provide_answer(meal, dessert),
   shell:provide_answer(sweet_preference, yes),
   shell:consult_expert(Conclusion).
Conclusion = serve_port.

?- shell:explain(serve_port).
Conclusion: serve_port
Reasoning: A dessert meal plus a sweet preference points to port.
```

This case study demonstrates the power of separating the inference logic (defined in the shell) from the domain rules (loaded with `load_kb/1`), allowing you to build new expert systems simply by swapping in different rule files.

## Optional Practice Problems

1. **Why Explanations**: Extend the `expert_shell` system to support `why` queries. When the system asks the user a question, the user should be able to type `why`, and the system should print the rules that are currently being evaluated.
2. **Semi-Sweet Wines**: In the `wine_advisor` project, add a `semi-sweet` preference and at least one semi-sweet wine to the database, and write a test asserting it is recommended for the right meals.
