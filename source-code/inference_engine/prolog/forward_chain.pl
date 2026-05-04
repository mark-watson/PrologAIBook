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
