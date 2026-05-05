# Planning and Scheduling

Planning — the automatic generation of action sequences to achieve goals — is a foundational AI problem, and Prolog is exceptionally well-suited for it. Prolog's backtracking search, unification, and declarative style make it natural to express planning domains and let the system find solutions.

## Classical Planning in Prolog

TBD: The STRIPS representation of actions (preconditions, add lists, delete lists). Implementing a simple STRIPS-style planner in Prolog.

The **strips_planner** project implements a STRIPS-style planner. Here is the file **strips_planner/prolog/strips.pl**:

```prolog
%% strips.pl - STRIPS-style planner
:- module(strips, [plan/3]).

%% plan(+InitState, +GoalState, -Plan)
plan(State, Goal, []) :-
    subset(Goal, State).
plan(State, Goal, [Action|Plan]) :-
    action(Action, Preconditions, AddList, DeleteList),
    subset(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    plan(NewState, Goal, Plan).

%% Domain-specific actions (blocks world logistics)
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
```

## The Blocks World

TBD: The classic AI planning domain. Implementing a blocks world planner that finds sequences of moves to achieve a goal configuration.

The **blocks_world** project implements a dedicated blocks world planner with cycle detection. Here is the file **blocks_world/prolog/blocks.pl**:

```prolog
%% blocks.pl - Blocks World planner
:- module(blocks, [blocks_plan/3, print_state/1]).

%% blocks_plan(+InitState, +GoalState, -Moves)
blocks_plan(State, Goal, []) :-
    subset(Goal, State), !.
blocks_plan(State, Goal, [Move|Moves]) :-
    blocks_move(State, Move, NewState),
    \+ blocks_plan_visited(NewState),
    assert(blocks_plan_visited(NewState)),
    blocks_plan(NewState, Goal, Moves).

:- dynamic blocks_plan_visited/1.

blocks_move(State, move(X, table, To), NewState) :-
    member(on_table(X), State),
    clear(X, State),
    block_in_state(To, State),
    dif(X, To),
    clear(To, State),
    select(on_table(X), State, S1),
    NewState = [on(X, To)|S1].
blocks_move(State, move(X, From, To), NewState) :-
    member(on(X, From), State),
    clear(X, State),
    block_in_state(To, State),
    dif(X, To),
    clear(To, State),
    select(on(X, From), State, S1),
    NewState = [on(X, To)|S1].
blocks_move(State, move_to_table(X, From), NewState) :-
    member(on(X, From), State),
    clear(X, State),
    select(on(X, From), State, S1),
    NewState = [on_table(X)|S1].

block_in_state(B, State) :- member(on_table(B), State).
block_in_state(B, State) :- member(on(B, _), State).
block_in_state(B, State) :- member(on(_, B), State).

clear(X, State) :- \+ member(on(_, X), State).
clear(table, _).

%% print_state(+State)
print_state(State) :-
    format("State: ~w~n", [State]).
```

## Planning with Constraints

TBD: Combining CLP(FD) with planning to handle temporal constraints, resource limits, and scheduling requirements.

## Partial-Order Planning

TBD: Implementing a partial-order planner that finds plans without committing to a total ordering of actions unnecessarily.

## Practical Scheduling Applications

TBD: Applying planning and constraint techniques to real-world scheduling problems — project scheduling, resource allocation, and timetabling.
