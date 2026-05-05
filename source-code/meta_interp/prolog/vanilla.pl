%% vanilla.pl - Vanilla meta-interpreter and proof-tree variant
:- module(vanilla, [
    mi_solve/1,
    mi_solve/2,
    mi_solve_proof/2,
    mi_solve_proof/3
]).

%% mi_solve(+Goal) - Vanilla meta-interpreter (user module context)
mi_solve(Goal) :- mi_solve(user, Goal).

%% mi_solve(+Module, +Goal) - Vanilla meta-interpreter with module context
mi_solve(_, true) :- !.
mi_solve(Mod, (A, B)) :- !, mi_solve(Mod, A), mi_solve(Mod, B).
mi_solve(Mod, Goal) :-
    clause(Mod:Goal, Body),
    mi_solve(Mod, Body).

%% mi_solve_proof(+Goal, -Proof) - Meta-interpreter with proof tree (user module)
mi_solve_proof(Goal, Proof) :- mi_solve_proof(user, Goal, Proof).

%% mi_solve_proof(+Module, +Goal, -Proof) - With module context
mi_solve_proof(_, true, true) :- !.
mi_solve_proof(Mod, (A, B), (PA, PB)) :- !,
    mi_solve_proof(Mod, A, PA),
    mi_solve_proof(Mod, B, PB).
mi_solve_proof(Mod, Goal, Goal-Proof) :-
    clause(Mod:Goal, Body),
    mi_solve_proof(Mod, Body, Proof).
