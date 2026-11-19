%% certainty.pl - A meta-interpreter that computes certainty factors
%%
%% Rules are written as cf_rule(Head, Body, CF) facts, where CF is
%% between 0.0 and 1.0. The interpreter proves a goal and computes
%% how certain the conclusion is:
%%   - a conjunction is as certain as its weakest part (min)
%%   - a rule multiplies its own CF by the CF of its body
%%   - when several proofs exist, the best one counts (max)
:- module(certainty, [
    mi_cf/3,
    best_cf/3
]).

%% mi_cf(+Module, +Goal, -CF)
%% One proof of Goal and its certainty. Backtracking gives others.
mi_cf(_, true, 1.0) :- !.
mi_cf(Mod, (A, B), CF) :- !,
    mi_cf(Mod, A, CF1),
    mi_cf(Mod, B, CF2),
    CF is min(CF1, CF2).
mi_cf(Mod, Goal, 1.0) :-
    predicate_property(Mod:Goal, built_in), !,
    call(Mod:Goal).
mi_cf(Mod, Goal, CF) :-
    Mod:cf_rule(Goal, Body, RuleCF),
    mi_cf(Mod, Body, BodyCF),
    CF is RuleCF * BodyCF.

%% best_cf(+Module, +Goal, -CF)
%% The highest certainty over all proofs of Goal. Fails if Goal has
%% no proof.
best_cf(Mod, Goal, CF) :-
    aggregate_all(max(C), mi_cf(Mod, Goal, C), CF),
    CF \== -inf.
