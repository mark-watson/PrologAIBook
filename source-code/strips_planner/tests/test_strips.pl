:- module(test_strips, []).
:- use_module(library(plunit)).
:- use_module('../prolog/strips').

:- begin_tests(strips_planner).

%% --- Blocks World Tests ---

test(blocks_pickup_dfs, [nondet]) :-
    InitState = [on_table(a), clear(a), hand_empty],
    GoalState = [holding(a)],
    plan(InitState, GoalState, Plan),
    Plan = [pickup(a)].

test(blocks_stack_two_bfs, [nondet]) :-
    InitState = [on_table(a), on_table(b), clear(a), clear(b), hand_empty],
    GoalState = [on(a, b)],
    plan_bfs(InitState, GoalState, Plan),
    last(Plan, stack(a, b)).

test(blocks_unstack_restack_visited, [nondet]) :-
    InitState = [on(a, b), on_table(b), clear(a), hand_empty],
    GoalState = [on(b, a)],
    plan_visited(InitState, GoalState, Plan),
    member(unstack(a, b), Plan),
    member(stack(b, a), Plan).

test(blocks_bfs_shortest, [nondet]) :-
    InitState = [on_table(a), on_table(b), clear(a), clear(b), hand_empty],
    GoalState = [on(a, b)],
    plan_bfs(InitState, GoalState, Plan),
    length(Plan, Len),
    Len =:= 2.  % pickup(a), stack(a,b)

test(blocks_visited_simple, [nondet]) :-
    InitState = [on_table(a), on_table(b), clear(a), clear(b), hand_empty],
    GoalState = [on(a, b)],
    plan_visited(InitState, GoalState, Plan),
    member(stack(a, b), Plan).

%% --- Logistics Domain Tests ---

test(logistics_truck_bfs, [nondet]) :-
    InitState = [pkg_at(pkg1, loc_a), truck_at(truck1, loc_a), free(truck1),
                 road(loc_a, loc_b), road(loc_b, loc_a)],
    GoalState = [pkg_at(pkg1, loc_b)],
    plan_bfs(InitState, GoalState, Plan),
    member(load_truck(pkg1, truck1, loc_a), Plan),
    member(drive(truck1, loc_a, loc_b), Plan),
    member(unload_truck(pkg1, truck1, loc_b), Plan).

test(logistics_bfs_shortest, [nondet]) :-
    InitState = [pkg_at(pkg1, loc_a), truck_at(truck1, loc_a), free(truck1),
                 road(loc_a, loc_b), road(loc_b, loc_a)],
    GoalState = [pkg_at(pkg1, loc_b)],
    plan_bfs(InitState, GoalState, Plan),
    length(Plan, Len),
    Len =:= 3.  % load, drive, unload

test(logistics_visited, [nondet]) :-
    InitState = [pkg_at(pkg1, loc_a), truck_at(truck1, loc_a), free(truck1),
                 road(loc_a, loc_b), road(loc_b, loc_a)],
    GoalState = [pkg_at(pkg1, loc_b)],
    plan_visited(InitState, GoalState, Plan),
    member(unload_truck(pkg1, truck1, loc_b), Plan).

%% --- Three-block tower with BFS ---

test(blocks_three_tower_bfs, [nondet]) :-
    InitState = [on_table(a), on_table(b), on_table(c),
                 clear(a), clear(b), clear(c), hand_empty],
    GoalState = [on(a, b), on(b, c)],
    plan_bfs(InitState, GoalState, Plan),
    length(Plan, Len),
    Len =:= 4.  % pickup(b), stack(b,c), pickup(a), stack(a,b)

test(blocks_swap_terminates, [nondet]) :-
    % Regression test: plain DFS did not terminate on this
    % 2-block swap; iterative deepening solves it in 4 steps
    % (unstack, putdown, pickup, stack).
    InitState = [on(a, b), on_table(b), clear(a), hand_empty],
    GoalState = [on(b, a)],
    plan(InitState, GoalState, Plan),
    length(Plan, Len),
    Len =:= 4.

test(visited_idempotent, [nondet]) :-
    % Two successive top-level calls must start from fresh visited
    % sets and return identical plans (no leaked asserts).
    InitState = [on_table(a), on_table(b), clear(a), clear(b), hand_empty],
    GoalState = [on(a, b)],
    plan_visited(InitState, GoalState, Plan1),
    plan_visited(InitState, GoalState, Plan2),
    Plan1 == Plan2.

test(plan_trace_valid_states, [nondet]) :-
    % Every state along a plan trace must satisfy valid_state/1.
    InitState = [on_table(a), on_table(b), clear(a), clear(b), hand_empty],
    GoalState = [on(a, b)],
    plan(InitState, GoalState, Plan),
    valid_state(InitState),
    plan_trace(InitState, Plan, Trace),
    forall(member(S, Trace), valid_state(S)).

:- end_tests(strips_planner).

%% plan_trace(+State, +Plan, -States)
%% Simulate Plan from State, collecting the full state sequence.
plan_trace(State, [], [State]).
plan_trace(State, [Action|Plan], [State|States]) :-
    action(Action, Preconditions, AddList, DeleteList),
    holds(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    plan_trace(NewState, Plan, States).
