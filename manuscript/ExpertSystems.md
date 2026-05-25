# Expert Systems and Rule-Based AI

Expert systems were one of the earliest commercial successes of AI, and Prolog is an ideal language for building them. In this chapter we build a complete expert system shell and demonstrate it with practical examples.

{width: "80%"}
![Architecture diagram for the Expert Shell example](FIG_expert_shell.jpg)

{width: "80%"}
![Architecture diagram for the Wine Advisor example](FIG_wine_advisor.jpg)

## What Is an Expert System?

TBD: Brief history and architecture of expert systems — knowledge base, inference engine, explanation facility, and user interface.

## Building an Expert System Shell in Prolog

TBD: Implementing a reusable expert system shell that supports rules with confidence factors, backward chaining, and an explanation facility that shows the chain of reasoning.

The **expert_shell** project provides a domain-independent shell. Here is the file **expert_shell/prolog/shell.pl**:

```prolog
:- module(shell, [
    consult_expert/1,
    explain/1,
    ask_question/1
]).

:- dynamic known/2.  % known(Attribute, Value) - user-provided facts

%% consult_expert(-Conclusion) - Main entry point
consult_expert(Conclusion) :-
    retractall(known(_, _)),
    hypothesis(Conclusion),
    !.

%% explain(+Conclusion) - Show reasoning chain
explain(Conclusion) :-
    hypothesis_explanation(Conclusion, Explanation),
    format("Conclusion: ~w~n", [Conclusion]),
    format("Reasoning: ~w~n", [Explanation]).

%% ask_question(+Attribute) - Ask user for information
ask_question(Attribute) :-
    format("~nWhat is the value of ~w? ", [Attribute]),
    read(Value),
    assert(known(Attribute, Value)).

%% Hypothesis rules (to be extended in domain-specific knowledge bases)
hypothesis(unknown) :-
    format("Could not determine a conclusion from the given facts.~n").

hypothesis_explanation(
    unknown,
    'Insufficient data to reach a conclusion.').
```

## Knowledge Acquisition and Rule Representation

TBD: Representing domain knowledge as Prolog rules. Strategies for organizing large rule bases. Using operator definitions for readable rule syntax.

## Explanation Facilities

TBD: Implementing "how" and "why" explanations so the system can justify its conclusions to the user.

## Case Study: A Wine Selection Advisor

TBD: A complete example expert system that recommends wines based on meal type, flavor preferences, and budget.

The **wine_advisor** project implements a rule-based wine recommender. Here is the file **wine_advisor/prolog/wine_rules.pl**:

```prolog
    recommend_wine/3
]).

%% recommend_wine(+MealType, +Preference, -Wine)
recommend_wine(MealType, Preference, Wine) :-
    wine(Wine, Color, Body, _Sweetness),
    meal_pairs_with(MealType, Color),
    preference_matches(Preference, Body).

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

%% Preference matching
preference_matches(bold, full).
preference_matches(moderate, medium).
preference_matches(light, light).
preference_matches(any, _).
```

## Case Study: A Fault Diagnosis System

TBD: Diagnosing hardware or network faults using rule-based reasoning with an explanation trace.
