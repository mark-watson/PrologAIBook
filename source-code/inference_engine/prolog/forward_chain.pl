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
