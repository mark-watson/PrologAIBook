# Expert Systems and Rule-Based AI

Expert systems were one of AI's first commercial successes, and Prolog is a natural language for building them. In this chapter we build an expert system shell and use it with two wine-selection knowledge bases.

{width: "80%"}
![Architecture diagram for the Expert Shell example](FIG_expert_shell.jpg)

## What Is an Expert System?

An **expert system** is a program that makes decisions the way a human expert does in a narrow domain. The rule-based systems of the 1970s and 1980s, such as MYCIN and DENDRAL, were among the first AI programs to solve real problems.

An expert system has four parts:
1. **Knowledge base (KB)**: Domain facts and rules, usually written as IF-THEN statements.
2. **Inference engine**: Applies the rules to the knowledge base to prove a hypothesis or derive new facts, by forward chaining (data-driven) or backward chaining (goal-driven).
3. **Explanation facility**: Tells the user *how* the system reached a conclusion, or *why* it is asking a question.
4. **User interface**: Asks the user for missing information and shows the conclusions.

Prolog already has a backward-chaining inference engine with backtracking, so we only need to write the other three parts.

## Building an Expert System Shell in Prolog

Instead of writing an expert system for one domain, we build a **domain-independent shell**. The shell asks questions, stores the answers, and explains conclusions. The domain knowledge lives in a separate file that the shell loads with `load_kb/1`.

The shell stores the user's answers as `known(Attribute, Value)` facts. Prolog runs the rules by backward chaining. When a rule needs an attribute that is not yet known, the shell asks the user, records the answer, and carries on. Here is the file **expert_shell/prolog/shell.pl**:

```prolog
%% shell.pl - Expert system shell with backward
%% chaining and explanations
:- module(shell, [
    consult_expert/1,
    explain/1,
    ask_question/1,
    provide_answer/2,
    reset_known/0,
    load_kb/1,
    op(1100, fx, if),
    op(1050, xfx, then),
    op(1000, xfy, and)
]).

%% Operators for knowledge bases written as readable rules:
%%   if meal is dessert and sweet_preference is yes then serve_port.
%% is/2 is already a standard operator (priority 700).

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
    (   user:hypothesis(Conclusion)
    ;   kb_rule(Conclusion, Conditions),
        maplist(check, Conditions)
    ).
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
    kb_rule(C, Conditions),
    maplist(known_condition, Conditions),
    !,
    maplist(condition_text, Conditions, Texts),
    atomic_list_concat(Texts, ' and ', Because),
    format(atom(E), '~w because ~w.', [C, Because]).

explanation_text(C, E) :-
    hypothesis_explanation(C, E).

%% known_condition/1 and condition_text/2 build the text of an
%% explanation from the conditions of the rule that fired.
known_condition(A == V) :- known(A, V).

condition_text(A == V, Text) :-
    format(atom(Text), '~w is ~w', [A, V]).

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

%% load_kb(+File) - Load a knowledge-base file and clear any KB
%% loaded before. The file may hold two kinds of terms:
%%   - Prolog clauses for hypothesis/1 and hypothesis_explanation/2,
%%     whose conditions call shell:check/1. These go into module user.
%%   - Readable rules such as
%%       if meal is dessert and sweet_preference is yes then serve_port.
%%     These become kb_rule(Conclusion, Conditions) facts.
%% Terms are read with this module's operators, so the file needs no
%% op/3 directives.
:- dynamic kb_file/1, kb_rule/2.

load_kb(File) :-
    retractall(kb_file(_)),
    unload_old_kb,
    assertz(kb_file(File)),
    setup_call_cleanup(
        open(File, read, In),
        load_terms(In),
        close(In)).

load_terms(In) :-
    read_term(In, Term, [module(shell)]),
    (   Term == end_of_file
    ->  true
    ;   add_kb_term(Term),
        load_terms(In)
    ).

add_kb_term(if Conds then Conclusion) :- !,
    and_list(Conds, Conditions),
    assertz(kb_rule(Conclusion, Conditions)).
add_kb_term(Term) :-
    assertz(user:Term).

%% and_list(+AndTerm, -Conditions): a is b and c is d gives
%% [a == b, c == d], the form check/1 expects.
and_list(A and B, [C|Cs]) :- !,
    is_condition(A, C),
    and_list(B, Cs).
and_list(A, [C]) :-
    is_condition(A, C).

is_condition(Attr is Value, Attr == Value).

unload_old_kb :-
    retractall(kb_rule(_, _)),
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

The shell's key predicates:

- **`consult_expert/1`** is the main entry point. With a KB loaded, it tries the KB's `hypothesis/1` clauses and then its readable rules, and returns the first conclusion that holds. With no KB, it returns `unknown`. Answers persist between calls, so call `reset_known/0` to start a fresh consultation.
- **`check/1`** tests a condition `Attribute == Value`. If the attribute is known, it compares the stored value. If not, it asks the question and then compares. If the attribute is known with a different value, it fails at once without asking again.
- **`explain/1`** prints an explanation. It uses the KB's `hypothesis_explanation/2` text if there is one. For a readable rule, it builds the text from the conditions of the rule that fired.
- **`ask_question/1`** reads a line with `read_line_to_string/2`, strips a trailing `.`, converts numbers, and treats end of file as a reason to stop.
- **`provide_answer/2`** supplies an answer without asking. Tests and scripts use it.
- **`load_kb/1`** loads a knowledge-base file and clears any KB loaded before.

## Knowledge Acquisition and Rule Representation

**Knowledge acquisition** is the work of getting knowledge from human experts and writing it down as rules. The shell accepts rules in two forms.

#### Rules as Prolog Clauses
A knowledge base can define `hypothesis/1` clauses whose conditions call `shell:check/1`, plus `hypothesis_explanation/2` facts that explain each conclusion. For example:

```prolog
hypothesis(diagnose_internet_issue) :-
    shell:check(router_lights == off),
    shell:check(cables_plugged_in == yes).
```

This form can use any Prolog goal in a condition, but a domain expert who does not know Prolog will struggle to read it.

#### Readable Rules with Custom Operators
Prolog lets you define your own **operators** with `op/3`. The shell exports three:

```prolog
op(1100, fx, if),
op(1050, xfx, then),
op(1000, xfy, and)
```

With these, the Prolog reader parses

```prolog
if meal is dessert and sweet_preference is yes then serve_port.
```

as the term `if(then(and(is(meal, dessert), is(sweet_preference, yes)), serve_port))`. The priorities decide how the term nests: `and` (1000) binds tighter than `then` (1050), which binds tighter than `if` (1100). `is` is already a standard operator with priority 700. The rule is just data: nothing evaluates `meal is dessert` as arithmetic.

`load_kb/1` reads each term with `read_term(In, Term, [module(shell)])`, so the shell's operators apply and the KB file needs no `op/3` directives. `add_kb_term/1` turns each `if ... then` term into a fact such as `kb_rule(serve_port, [meal == dessert, sweet_preference == yes])`, the form `check/1` expects. Here is the file **expert_shell/prolog/rules_kb.pl**:

```prolog
% rules_kb.pl - Wine-selection knowledge base in readable rule form.
% Load with shell:load_kb/1. Each rule reads:
%   if Attribute is Value and ... then Conclusion.
% The shell asks for any attribute it does not know yet and builds
% the explanation from the conditions of the rule that fired.

if meal is dessert and sweet_preference is yes then serve_port.
if meal is red_meat and bold_preference is yes then serve_cabernet.
if meal is red_meat then serve_merlot.
if meal is fish and light_preference is yes then serve_sauvignon_blanc.
if meal is fish then serve_chardonnay.
if meal is poultry then serve_pinot_noir.
```

Because each rule is data, the shell can explain it with no extra text from the author. `explain/1` lists the conditions of the rule that fired. Rule order matters: the shell tries rules from top to bottom, so put specific rules (fish and a light preference) before general ones (fish).

## Explanation Facilities

Explaining its reasoning is a defining feature of an expert system.
- **"How" explanations** say how the system reached a conclusion, by listing the rules and facts it used.
- **"Why" explanations** say why the system is asking a question. When the system asks something, the user can type `why`, and the system shows the rule it is trying to prove.

Our shell gives "how" explanations through `explain/1`. For readable rules it builds them from the rule's conditions. For `hypothesis/1` clauses it uses the author's `hypothesis_explanation/2` text. A larger system could use the proof-tree meta-interpreter from the previous chapter to explain deeper chains of rules. Practice problem 1 adds "why" explanations.

## Case Study: A Wine Selection Advisor

Not every rule-based program needs a shell. The **wine_advisor** project answers one question, which wines suit a meal and a taste, with plain Prolog rules and no dialog.

It uses two kinds of rules:
1. **Meal pairing rules** decide which wine colors (red, white, rose) go with a meal (fish, red meat, dessert, and so on).
2. **Preference rules** match the user's taste to the wine. The preference is a body (`bold`, `moderate`, `light`), a sweetness (`sweet`, `dry`), or `any`.

{width: "80%"}
![Architecture diagram for the Wine Advisor example](FIG_wine_advisor.jpg)

Here is the file **wine_advisor/prolog/wine_rules.pl**:

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
meal_pairs_with(dessert, red).    % port and other red dessert wines
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

Body and sweetness are separate dimensions. A body preference says nothing about sweetness, and a sweetness preference says nothing about body:

```prolog
?- findall(W, recommend_wine(red_meat, bold, W), Ws).
Ws = [cabernet_sauvignon, port].

?- findall(W, recommend_wine(dessert, sweet, W), Ws).
Ws = [riesling, port].
```

The first answer shows a weakness of the rules. Port is a full-bodied red, so it passes every test, yet few people drink port with steak. Real experts know many such exceptions, and capturing them is the hard part of building an expert system. Practice problem 2 asks you to add one.

## Case Study: A Pluggable Knowledge Base

The shell also loads knowledge bases written as Prolog clauses. The file **expert_shell/prolog/sample_kb.pl** holds four wine hypotheses whose conditions call `shell:check/1`:

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

hypothesis(serve_cabernet) :-
    shell:check(meal == red_meat),
    shell:check(bold_preference == yes).

hypothesis(serve_sauvignon_blanc) :-
    shell:check(meal == fish),
    shell:check(light_preference == yes).

%% Riesling comes last: its first condition asks about sweetness,
%% which the rules above settle by asking about the meal first.
hypothesis(serve_riesling) :-
    shell:check(sweet_preference == yes),
    \+ shell:known(meal, dessert).

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

From the `expert_shell` directory, load the KB and run a consultation. Here we supply the answers with `provide_answer/2`:

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

Note the order of the hypotheses. The shell tries them from top to bottom, and `serve_riesling` starts by asking about sweetness. If it came first, a user who wants red meat would still be asked about sweet wine. Putting it last lets the rules that ask about the meal settle most cases first.

To try an interactive consultation with the readable rules, run `make consult`:

```text
What is the value of meal? fish
What is the value of light_preference? no
Conclusion: serve_chardonnay
Reasoning: serve_chardonnay because meal is fish.
```

The shell keeps the inference logic apart from the domain rules, so you build a new expert system by writing a new rule file.

## Optional Practice Problems

1. **Why Explanations**: In `expert_shell`, let the user answer a question with `why`. The shell should print the readable rule it is trying to prove and then ask the question again. (Hint: pass the current rule to `check/1`, or keep it in a dynamic fact while its conditions are checked.)
2. **Exceptions**: In `wine_advisor`, add `avoid(Meal, Wine)` facts such as `avoid(red_meat, port)` and change `recommend_wine/3` to skip them. Add a test.
3. **Certainty**: Extend the readable rule syntax to `if ... then Conclusion with 0.8` and have `consult_expert/1` return the conclusion with the highest certainty instead of the first.
