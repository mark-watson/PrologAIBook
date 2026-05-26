%% strips.pl - STRIPS-style planner with multiple domains
:- module(strips, [
    plan/3,
    plan_bfs/3,
    plan_visited/3
]).

%% holds(+Conditions, +State)
%% True when every condition in Conditions is present in State.
%% Uses member/2 (not memberchk) so that variables in Conditions
%% can be bound to any matching element in State.
holds([], _).
holds([C|Cs], State) :- member(C, State), holds(Cs, State).

%% plan(+InitState, +GoalState, -Plan)
%% Depth-first search through the state space.
%% InitState and GoalState are lists of ground atoms (fluents).
plan(State, Goal, []) :-
    holds(Goal, State).
plan(State, Goal, [Action|Plan]) :-
    action(Action, Preconditions, AddList, DeleteList),
    holds(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    plan(NewState, Goal, Plan).

%% plan_bfs(+InitState, +GoalState, -Plan)
%% Breadth-first search — guaranteed to find the shortest plan.
plan_bfs(State, Goal, Plan) :-
    plan_bfs_queue([bfs_node(State, [])], Goal, RevPlan),
    reverse(RevPlan, Plan).

plan_bfs_queue([bfs_node(State, Actions)|_], Goal, Actions) :-
    holds(Goal, State), !.
plan_bfs_queue([bfs_node(State, Actions)|Rest], Goal, Plan) :-
    findall(
        bfs_node(NewState, [Action|Actions]),
        (   action(Action, Preconditions, AddList, DeleteList),
            holds(Preconditions, State),
            subtract(State, DeleteList, TempState),
            union(TempState, AddList, NewState)
        ),
        Children
    ),
    append(Rest, Children, NewQueue),
    plan_bfs_queue(NewQueue, Goal, Plan).

%% plan_visited(+InitState, +GoalState, -Plan)
%% DFS with cycle detection — avoids revisiting states.
plan_visited(State, Goal, Plan) :-
    retractall(plan_visited_state(_)),
    plan_visited_dfs(State, Goal, [], Plan).

:- dynamic plan_visited_state/1.

plan_visited_dfs(State, Goal, _ActionPath, []) :-
    holds(Goal, State), !.
plan_visited_dfs(State, Goal, ActionPath, [Action|Plan]) :-
    action(Action, Preconditions, AddList, DeleteList),
    holds(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    \+ plan_visited_state(NewState),
    assert(plan_visited_state(NewState)),
    plan_visited_dfs(NewState, Goal, [Action|ActionPath], Plan).


%% ============================================================
%% Domain: Blocks World (gripper-style operators)
%% ============================================================

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


%% ============================================================
%% Domain: Logistics (trucks and planes moving packages)
%% ============================================================
%% Uses distinct predicate names to prevent variable-binding
%% ambiguity: pkg_at/2, truck_at/2, plane_at/2.

%% Load a package onto a truck at a location
action(
    load_truck(Pkg, Truck, Loc),
    [pkg_at(Pkg, Loc), truck_at(Truck, Loc), free(Truck)],
    [in(Pkg, Truck)],
    [pkg_at(Pkg, Loc), free(Truck)]
).

%% Unload a package from a truck at a location
action(
    unload_truck(Pkg, Truck, Loc),
    [in(Pkg, Truck), truck_at(Truck, Loc)],
    [pkg_at(Pkg, Loc), free(Truck)],
    [in(Pkg, Truck)]
).

%% Drive a truck between two locations
action(
    drive(Truck, From, To),
    [truck_at(Truck, From), road(From, To)],
    [truck_at(Truck, To)],
    [truck_at(Truck, From)]
).

%% Load a package onto a plane at an airport
action(
    load_plane(Pkg, Plane, Loc),
    [pkg_at(Pkg, Loc), plane_at(Plane, Loc), free(Plane)],
    [in(Pkg, Plane)],
    [pkg_at(Pkg, Loc), free(Plane)]
).

%% Unload a package from a plane at an airport
action(
    unload_plane(Pkg, Plane, Loc),
    [in(Pkg, Plane), plane_at(Plane, Loc)],
    [pkg_at(Pkg, Loc), free(Plane)],
    [in(Pkg, Plane)]
).

%% Fly a plane between airports
action(
    fly(Plane, From, To),
    [plane_at(Plane, From), flight(From, To)],
    [plane_at(Plane, To)],
    [plane_at(Plane, From)]
).
