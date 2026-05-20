:- module(robot_agent, [
    run_simulation/1
]).

:- use_module(behavior_trees).

% Import multifile hooks
:- multifile behavior_trees:user_condition/1.
:- multifile behavior_trees:user_action/2.

% Dynamic state representing the robot's environment and internals
:- dynamic battery/1.
:- dynamic dusty/1.

% --- Define Conditions ---

% Battery is low if it's strictly below 30%
behavior_trees:user_condition(battery_low) :-
    battery(Level),
    Level < 30,
    format('[Cond] Battery is low: ~w%~n', [Level]).

% Dust is present if dusty(true) is asserted
behavior_trees:user_condition(dust_present) :-
    dusty(true),
    format('[Cond] Dust detected in room!~n').

% --- Define Actions ---

% Recharge Action
behavior_trees:user_action(recharge, success) :-
    battery(Level),
    NewLevel is min(100, Level + 50),
    retractall(battery(_)),
    assertz(battery(NewLevel)),
    format('[Action] Charging... Battery increased from ~w% to ~w%~n', [Level, NewLevel]).

% Clean Action
behavior_trees:user_action(clean, success) :-
    battery(Level),
    NewLevel is max(0, Level - 10),
    retractall(battery(_)),
    assertz(battery(NewLevel)),
    retractall(dusty(_)),
    assertz(dusty(false)),
    format('[Action] Cleaning dust... Battery at ~w%~n', [NewLevel]).

% Patrol Action
behavior_trees:user_action(patrol, success) :-
    battery(Level),
    NewLevel is max(0, Level - 15),
    retractall(battery(_)),
    assertz(battery(NewLevel)),
    % Randomly generate new dust on patrol to keep the simulation interesting
    maybe_generate_dust,
    format('[Action] Patrolling rooms... Battery at ~w%~n', [NewLevel]).

% Helper to randomly generate dust
maybe_generate_dust :-
    random(0, 10, R),
    (   R > 6
    ->  retractall(dusty(_)),
        assertz(dusty(true)),
        format('[Env] Dust has settled in the room.~n')
    ;   true
    ).

% --- Initialize the Behavior Tree ---

:- define_tree(cleaning_robot,
    selector([
        sequence([
            condition(battery_low),
            action(recharge)
        ]),
        sequence([
            condition(dust_present),
            action(clean)
        ]),
        action(patrol)
    ])
).

% --- Run Simulation ---

% Run the behavior tree for N ticks
run_simulation(Ticks) :-
    % Initialize state: full battery, no dust
    retractall(battery(_)),
    retractall(dusty(_)),
    assertz(battery(100)),
    assertz(dusty(false)),
    format('--- Starting Robot Simulation with BT ---~n'),
    run_ticks(1, Ticks).

run_ticks(Current, Max) :-
    Current > Max,
    !,
    format('--- Simulation Completed ---~n').
run_ticks(Current, Max) :-
    format('~n[Tick ~w]~n', [Current]),
    battery(Level),
    dusty(D),
    format('[State] Battery: ~w%, Dusty: ~w~n', [Level, D]),
    tick(cleaning_robot, Status),
    format('[BT] Root execution status: ~w~n', [Status]),
    Next is Current + 1,
    run_ticks(Next, Max).
