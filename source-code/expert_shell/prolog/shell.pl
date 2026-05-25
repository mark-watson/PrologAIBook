%% shell.pl - Expert system shell with backward
%% chaining and explanations
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

%% TBD: Domain-specific rules will be loaded as separate knowledge bases
