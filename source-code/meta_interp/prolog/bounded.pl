%% bounded.pl - Bounded depth meta-interpreter
:- module(bounded, [
    mi_bounded/2,
    mi_bounded/3
]).

%% mi_bounded(+Goal, +MaxDepth) - Solve with depth limit (user module)
mi_bounded(Goal, MaxDepth) :- mi_bounded(user, Goal, MaxDepth).

%% mi_bounded(+Module, +Goal, +MaxDepth) - Solve with depth limit and module context
mi_bounded(_, true, _) :- !.
mi_bounded(_, _, D) :- D =< 0, !, fail.
mi_bounded(Mod, (A, B), D) :- !,
    mi_bounded(Mod, A, D),
    mi_bounded(Mod, B, D).
mi_bounded(Mod, Goal, D) :-
    D > 0,
    clause(Mod:Goal, Body),
    D1 is D - 1,
    mi_bounded(Mod, Body, D1).
