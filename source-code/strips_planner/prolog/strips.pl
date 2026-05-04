%% strips.pl - STRIPS-style planner
:- module(strips, [
    plan/3
]).

%% plan(+InitState, +GoalState, -Plan)
%% InitState and GoalState are lists of ground atoms (fluents)
plan(State, Goal, []) :-
    subset(Goal, State).
plan(State, Goal, [Action|Plan]) :-
    action(Action, Preconditions, AddList, DeleteList),
    subset(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    plan(NewState, Goal, Plan).

%% TBD: Define domain-specific actions
%% Example: logistics domain
action(
    pickup(X),
    [on_table(X), clear(X), hand_empty],
    [holding(X)],
    [on_table(X), clear(X), hand_empty]
).

action(
    putdown(X),
    [holding(X)],
    [on_table(X), clear(X), hand_empty],
    [holding(X)]
).

action(
    stack(X, Y),
    [holding(X), clear(Y)],
    [on(X, Y), clear(X), hand_empty],
    [holding(X), clear(Y)]
).

action(
    unstack(X, Y),
    [on(X, Y), clear(X), hand_empty],
    [holding(X), clear(Y)],
    [on(X, Y), clear(X), hand_empty]
).
