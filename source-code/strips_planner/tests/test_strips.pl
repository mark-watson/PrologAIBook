:- module(test_strips, []).
:- use_module(library(plunit)).
:- use_module('../prolog/strips').

:- begin_tests(strips_planner).

test(simple_plan, [nondet]) :-
    InitState = [on_table(a), clear(a), hand_empty],
    GoalState = [holding(a)],
    plan(InitState, GoalState, Plan),
    Plan = [pickup(a)].

:- end_tests(strips_planner).
