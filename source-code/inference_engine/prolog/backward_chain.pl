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
