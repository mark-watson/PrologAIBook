%% vanilla.pl - Vanilla meta-interpreter and proof-tree variant
:- module(vanilla, [
    mi_solve/1,
    mi_solve_proof/2
]).

%% mi_solve(+Goal) - Vanilla meta-interpreter
mi_solve(true) :- !.
mi_solve((A, B)) :- !, mi_solve(A), mi_solve(B).
mi_solve(Goal) :-
    clause(Goal, Body),
    mi_solve(Body).

%% mi_solve_proof(+Goal, -Proof) - Meta-interpreter with proof tree
mi_solve_proof(true, true) :- !.
mi_solve_proof((A, B), (PA, PB)) :- !,
    mi_solve_proof(A, PA),
    mi_solve_proof(B, PB).
mi_solve_proof(Goal, Goal-Proof) :-
    clause(Goal, Body),
    mi_solve_proof(Body, Proof).
