%% strips.pl - STRIPS-style planner with multiple domains
:- module(strips, [
    plan/3,
    plan_bfs/3,
    plan_visited/3,
    valid_state/1,
    action/4,
    holds/2
]).

%% holds(+Conditions, +State)
%% True when every condition in Conditions is present in State.
%% Uses member/2 (not memberchk) so that variables in Conditions
%% can be bound to any matching element in State.
holds([], _).
holds([C|Cs], State) :- member(C, State), holds(Cs, State).

%% plan(+InitState, +GoalState, -Plan)
%% Iterative-deepening search: plan_dfs/4 is run with depth limits
%% 1, 2, ..., 50 in turn.  Unlike plain DFS this always terminates
%% and finds a shortest plan; on exhaustion (no plan within the
%% depth bound) it fails cleanly.
plan(State, Goal, Plan) :-
    between(1, 50, Depth),
    plan_dfs(State, Goal, Depth, Plan), !.

%% plan_dfs(+State, +Goal, +DepthLeft, -Plan)
plan_dfs(State, Goal, _DepthLeft, []) :-
    holds(Goal, State).
plan_dfs(State, Goal, DepthLeft, [Action|Plan]) :-
    DepthLeft > 0,
    action(Action, Preconditions, AddList, DeleteList),
    holds(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    DepthLeft1 is DepthLeft - 1,
    plan_dfs(NewState, Goal, DepthLeft1, Plan).

%% plan_bfs(+InitState, +GoalState, -Plan)
%% Breadth-first search — guaranteed to find the shortest plan.
%% States are normalized with sort/2 and kept in a visited set so
%% each distinct state is enqueued at most once.
plan_bfs(State, Goal, Plan) :-
    sort(State, Key),
    plan_bfs_queue([bfs_node(State, [])], Goal, [bfs_key(Key)], RevPlan),
    reverse(RevPlan, Plan).

plan_bfs_queue([bfs_node(State, Actions)|_], Goal, _Seen, Actions) :-
    holds(Goal, State), !.
plan_bfs_queue([bfs_node(State, Actions)|Rest], Goal, Seen, Plan) :-
    findall(
        bfs_node(NewState, [Action|Actions]),
        (   action(Action, Preconditions, AddList, DeleteList),
            holds(Preconditions, State),
            subtract(State, DeleteList, TempState),
            union(TempState, AddList, NewState)
        ),
        Children
    ),
    % Normalize each child state with sort/2 and enqueue only
    % distinct states that have not been seen before.
    bfs_enqueue_unseen(Children, Seen, Fresh, Seen1),
    append(Rest, Fresh, NewQueue),
    plan_bfs_queue(NewQueue, Goal, Seen1, Plan).

%% Drop children whose sort/2-normalized state (wrapped in
%% bfs_key/1) has already been seen; add the kept states' keys.
bfs_enqueue_unseen([], Seen, [], Seen).
bfs_enqueue_unseen([bfs_node(S, _)|Nodes], Seen, Fresh, Seen1) :-
    sort(S, K),
    memberchk(bfs_key(K), Seen),
    !,
    bfs_enqueue_unseen(Nodes, Seen, Fresh, Seen1).
bfs_enqueue_unseen([bfs_node(S, A)|Nodes], Seen,
                   [bfs_node(S, A)|Fresh], Seen1) :-
    sort(S, K),
    bfs_enqueue_unseen(Nodes, [bfs_key(K)|Seen], Fresh, Seen1).

%% plan_visited(+InitState, +GoalState, -Plan)
%% DFS with cycle detection — avoids revisiting states.  The
%% visited set is passed as an explicit argument, so backtracking
%% automatically unwinds it (no surviving assertz leaks) and every
%% top-level call starts from a fresh set.
plan_visited(State, Goal, Plan) :-
    sort(State, Key),
    plan_visited_dfs(State, Goal, [Key], Plan).

plan_visited_dfs(State, Goal, _Visited, []) :-
    holds(Goal, State), !.
plan_visited_dfs(State, Goal, Visited, [Action|Plan]) :-
    action(Action, Preconditions, AddList, DeleteList),
    holds(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    sort(NewState, Key),
    \+ memberchk(Key, Visited),
    plan_visited_dfs(NewState, Goal, [Key|Visited], Plan).

%% valid_state(+State)
%% True when State (a list of fluents) contains no basic
%% contradictions: nothing may be both clear and have a block on
%% it, and nothing may be held while the hand is empty.
valid_state(State) :-
    \+ ( member(on(_, Y), State), member(clear(Y), State) ),
    \+ ( member(holding(_), State), member(hand_empty, State) ).


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
