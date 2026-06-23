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

Instead of hard-coding an expert system for a single domain, we can build a **domain-independent shell**. The shell defines the interactive loop, maintains the database of user-supplied facts, and provides explanation utilities, while the specific domain knowledge is loaded from a separate rules file.

To implement the shell, we use Prolog's dynamic database to store facts provided by the user during a session using `known/2` terms. Prolog's built-in backward-chaining engine automatically executes the rules. When a rule needs an attribute that is not yet known, the shell prompts the user, records the answer, and continues evaluation.

The **expert_shell** project provides a domain-independent shell. Here is the file **expert_shell/prolog/shell.pl**:

```prolog
 %% shell.pl - Expert system shell with backward chaining and explanations
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
2. **Flavor Preference Rules**: Matching the user's body preference (bold, light, moderate) with the wine's characteristics (full body, light body, medium body).

{width: "80%"}
![Architecture diagram for the Wine Advisor example](FIG_wine_advisor.jpg)

The **wine_advisor** project implements a rule-based wine recommender. Here is the file **wine_advisor/prolog/wine_rules.pl**:

```prolog
 %% wine_rules.pl - Wine selection expert system
:- module(wine_rules, [
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

As a final case study, we can implement a **Fault Diagnosis System** that diagnoses computer network issues. By combining our domain-independent shell (`shell.pl`) with network diagnostic rules, we can build an interactive system that helps users troubleshoot connectivity problems.

Here is the complete fault diagnosis knowledge base, **expert_shell/prolog/fault_diagnosis.pl**:

```prolog
 %% fault_diagnosis.pl - Network fault diagnosis rules
:- module(fault_diagnosis, [
    diagnose/1
]).

:- use_module(shell).

%% Import ask_question and known from shell
:- reexport(shell).

%% ask_if(+Attribute, +Value) - Check fact database or ask user
ask_if(Attribute, Value) :-
    known(Attribute, Value), !.
ask_if(Attribute, Value) :-
    \+ known(Attribute, _),
    ask_question(Attribute),
    known(Attribute, Value).

%% Knowledge base rules defining hypotheses
hypothesis(cable_unplugged) :-
    ask_if(ethernet_status, disconnected).

hypothesis(router_failure) :-
    ask_if(ethernet_status, connected),
    ask_if(router_lights, off).

hypothesis(dns_configuration_issue) :-
    ask_if(ethernet_status, connected),
    ask_if(router_lights, on),
    ask_if(ping_ip_address, success),
    ask_if(ping_domain_name, failure).

hypothesis(isp_outage) :-
    ask_if(ethernet_status, connected),
    ask_if(router_lights, on),
    ask_if(ping_ip_address, failure).

hypothesis(local_software_firewall) :-
    ask_if(ethernet_status, connected),
    ask_if(router_lights, on),
    ask_if(ping_domain_name, success),
    ask_if(browser_connect, failure).

%% Explanations for each conclusion
hypothesis_explanation(cable_unplugged,
    'Your Ethernet cable is disconnected. Please plug it in securely and retry.').
hypothesis_explanation(router_failure,
    'Your router has no power or is failing. Check power cables and cycle the router power.').
hypothesis_explanation(dns_configuration_issue,
    'You can connect to raw IP addresses but not domain names. Your DNS server configuration is likely broken.').
hypothesis_explanation(isp_outage,
    'You cannot ping external IP addresses. This indicates a physical line issue or ISP outage.').
hypothesis_explanation(local_software_firewall,
    'Pings are successful, but browser traffic is blocked. A local firewall or proxy is likely blocking HTTP ports.').
```

### Running the Diagnosis System

You can run the network troubleshooter in the SWI-Prolog REPL:

```prolog
?- consult_expert(Conclusion).

What is the value of ethernet_status? connected.

What is the value of router_lights? on.

What is the value of ping_ip_address? success.

What is the value of ping_domain_name? failure.

Conclusion = dns_configuration_issue.

?- explain(dns_configuration_issue).
Conclusion: dns_configuration_issue
Reasoning: You can connect to raw IP addresses but not domain names. Your DNS server configuration is likely broken.
```

This case study demonstrates the power of separating the inference logic (defined in the shell) from the domain rules (defined in the fault diagnosis module), allowing you to build new expert systems simply by swapping in different rule bases.

## Optional Practice Problems

1. **Why Explanations**: Extend the `expert_shell` system to support `why` queries. When the system asks the user a question, the user should be able to type `why`, and the system should print the rules that are currently being evaluated.
2. **Sweetness Recommendation**: In the `wine_advisor` project, add a new attribute for "sweetness" (e.g., dry, semi-sweet, sweet) and update the recommendation rules to recommend dessert wines.
