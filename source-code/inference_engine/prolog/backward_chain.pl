%% backward_chain.pl - Backward chaining with explanation traces
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
