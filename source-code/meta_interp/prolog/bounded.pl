%% bounded.pl - Bounded depth meta-interpreter
:- module(bounded, [
    mi_bounded/2
]).

%% mi_bounded(+Goal, +MaxDepth) - Solve with depth limit
mi_bounded(true, _) :- !.
mi_bounded(_, D) :- D =< 0, !, fail.
mi_bounded((A, B), D) :- !,
    mi_bounded(A, D),
    mi_bounded(B, D).
mi_bounded(Goal, D) :-
    D > 0,
    clause(Goal, Body),
    D1 is D - 1,
    mi_bounded(Body, D1).
