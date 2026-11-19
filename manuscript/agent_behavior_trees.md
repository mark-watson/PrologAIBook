# Agent Behavior Trees

Controlling an agent's behavior is a central problem in robotics and game AI. Developers long used **finite state machines (FSMs)**, which are simple to write, but as states and transitions multiply, the transition graph becomes a tangle that is hard to change.

**Behavior trees (BTs)** organize decisions as a tree of nodes instead of a graph of states. Each *tick* evaluates the tree from the root and picks actions based on conditions in the environment.

Behavior trees are:
- **Modular**: You can design and test each subtree on its own.
- **Easy to extend**: A new behavior is a new branch; existing branches do not change.
- **Readable**: The tree reads like a priority list: "if the battery is low, charge; otherwise, if there is dust, clean; otherwise, patrol".

Prolog suits behavior trees well. A tree is a Prolog term, and pattern matching and recursion evaluate it, so the whole interpreter takes about 100 lines.


{width: "80%"}
![Architecture diagram for the Agent Behavior Trees example](FIG_agent_behavior_trees.jpg)


## Behavior Tree Node Types

Every tick of a node returns one of three statuses: `success`, `failure`, or `running` (the node is still working and needs more ticks). Our interpreter has four node types:
1. **Sequence (`sequence([Children])`)**: Ticks the children in order. It stops and returns the status of the first child that does not succeed, and succeeds if all do. (Like a logical AND.)
2. **Selector (`selector([Children])`)**: Ticks the children in order. It stops and returns the status of the first child that does not fail, and fails if all do. (Like a logical OR; it gives fallbacks.)
3. **Condition (`condition(Name)`)**: Tests something. Returns `success` if it holds and `failure` otherwise.
4. **Action (`action(Name)`)**: Does something and returns `success`, `failure`, or `running`.

---

## Implementing the BT Engine in Prolog

The engine walks the tree by pattern matching on node terms. The conditions and actions come from the agent: the engine declares two *multifile* hook predicates, `user_condition/1` and `user_action/2`, and any module can add clauses to them. (The Prolog Agents chapter used a module argument instead; multifile hooks are the other common way to let one module call code defined in another.)

Here is the file **agent_behavior_trees/prolog/behavior_trees.pl**:

```prolog
:- module(behavior_trees, [
    tick/2,
    define_tree/2
]).

/** <module> Behavior Trees Engine
 *
 * A small Behavior Tree interpreter in Prolog.
 * Supports:
 *   - sequence([Children])
 *   - selector([Children]) (fallback)
 *   - condition(Name)
 *   - action(Name)
 */

:- dynamic tree_definition/2.

% Define a tree name and its root node
define_tree(Name, RootNode) :-
    retractall(tree_definition(Name, _)),
    assertz(tree_definition(Name, RootNode)).

% Tick the entire tree by name
tick(TreeName, Status) :-
    tree_definition(TreeName, RootNode),
    !,
    tick_node(RootNode, Status).

% --- Node Tick Implementation ---

% 1. Sequence Node: Ticks children in order. 
%    - If a child fails, sequence fails.
%    - If a child returns 'running', sequence returns 'running'.
%    - If all children succeed, sequence succeeds.
tick_node(sequence(Children), Status) :-
    tick_sequence(Children, Status).

% 2. Selector Node (Fallback): Ticks children in order.
%    - If a child succeeds, selector succeeds.
%    - If a child returns 'running', selector returns 'running'.
%    - If all children fail, selector fails.
tick_node(selector(Children), Status) :-
    tick_selector(Children, Status).

% 3. Condition Node: Evaluates a user-defined condition predicate.
%    - Returns 'success' if the condition is true.
%    - Returns 'failure' if the condition is false.
tick_node(condition(CondName), Status) :-
    (   call_condition(CondName)
    ->  Status = success
    ;   Status = failure
    ).

% 4. Action Node: Executes a user-defined action predicate.
%    - The action predicate must bind its
%      status argument
%      (success, failure, or running).
tick_node(action(ActionName), Status) :-
    call_action(ActionName, Status).

% --- Helper Predicates for Composites ---

% Sequence traversal
tick_sequence([], success).
tick_sequence([Child|Rest], Status) :-
    tick_node(Child, ChildStatus),
    (   ChildStatus = success
    ->  tick_sequence(Rest, Status)
    ;   Status = ChildStatus  % either 'failure' or 'running'
    ).

% Selector traversal
tick_selector([], failure).
tick_selector([Child|Rest], Status) :-
    tick_node(Child, ChildStatus),
    (   ChildStatus = failure
    ->  tick_selector(Rest, Status)
    ;   Status = ChildStatus  % either 'success' or 'running'
    ).

% --- Hooks for Conditions and Actions ---
% An agent module adds clauses to these multifile predicates:
%   behavior_trees:user_condition(Name)        succeeds if true
%   behavior_trees:user_action(Name, Status)   performs the action
:- multifile user_condition/1.
:- multifile user_action/2.

call_condition(CondName) :-
    user_condition(CondName).

% An action that is not defined, or whose clauses all fail, is an
% error: silently failing would make the whole tick fail with no
% explanation.
call_action(ActionName, Status) :-
    (   user_action(ActionName, Status0)
    ->  must_be(oneof([success, failure, running]), Status0),
        Status = Status0
    ;   existence_error(bt_action, ActionName)
    ).
```

`call_action/2` checks the action's status with `must_be/2` and raises an error for an undefined action. Without that check, a misspelled action name would make the whole tick fail with no message.

---

## Defining a Robot Agent

Now we program a cleaning robot with the engine. The robot has a battery and a room that may be dusty. Its tree, in priority order:
- **First**: If it needs to charge, recharge.
- **Second**: If there is dust, clean.
- **Otherwise**: Patrol the rooms, which sometimes lets dust settle.

Here is the file **agent_behavior_trees/prolog/robot_agent.pl**:

```prolog
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
:- dynamic charging/0.

% --- Define Conditions ---

% The robot needs to charge if the battery is below 30%, or if it has
% started charging and is not finished. Without the second case, the
% robot would stop charging as soon as the battery passed 30%.
behavior_trees:user_condition(needs_charge) :-
    (   charging
    ->  format('[Cond] Still charging~n')
    ;   battery(Level),
        Level < 30,
        format('[Cond] Battery is low: ~w%~n', [Level])
    ).

% Dust is present if dusty(true) is asserted
behavior_trees:user_condition(dust_present) :-
    dusty(true),
    format('[Cond] Dust detected in room!~n').

% --- Define Actions ---

% Recharge Action: adds 25% per tick. It returns running until the
% battery reaches 80%, so it takes several ticks.
behavior_trees:user_action(recharge, Status) :-
    battery(Level),
    NewLevel is min(100, Level + 25),
    retractall(battery(_)),
    assertz(battery(NewLevel)),
    (   NewLevel >= 80
    ->  retractall(charging),
        Status = success
    ;   ( charging -> true ; assertz(charging) ),
        Status = running
    ),
    format('[Action] Charging... Battery ~w% -> ~w% (~w)~n',
        [Level, NewLevel, Status]).

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
    % Randomly generate new dust on patrol to keep the simulation
    % interesting
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
            condition(needs_charge),
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
    % Initialize state: full battery, no dust. A fixed random seed
    % makes the dust, and so the whole run, the same every time.
    set_random(seed(7)),
    retractall(battery(_)),
    retractall(dusty(_)),
    retractall(charging),
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
```

---

## Simulating the Agent

Recharging shows how `running` works. Each tick adds 25% to the battery, and `recharge` returns `running` until the battery reaches 80%. A tree has no memory of which node was running, so on the next tick the root starts again from the top. If the first branch tested only "battery below 30%", the robot would stop charging once the battery passed 30% and go back to patrolling. So the robot keeps a `charging` fact while it charges, and `needs_charge` holds while that fact exists. (Some behavior tree libraries add *memory* nodes that resume the running child instead.)

`make run` runs the same simulation for 12 ticks. Because `run_simulation/1` sets a fixed random seed, you will see this exact trace:

{linenos=off}
~~~~~~~~
--- Starting Robot Simulation with BT ---

[Tick 1]
[State] Battery: 100%, Dusty: false
[Action] Patrolling rooms... Battery at 85%
[BT] Root execution status: success

[Tick 2]
[State] Battery: 85%, Dusty: false
[Action] Patrolling rooms... Battery at 70%
[BT] Root execution status: success

[Tick 3]
[State] Battery: 70%, Dusty: false
[Action] Patrolling rooms... Battery at 55%
[BT] Root execution status: success

[Tick 4]
[State] Battery: 55%, Dusty: false
[Action] Patrolling rooms... Battery at 40%
[BT] Root execution status: success

[Tick 5]
[State] Battery: 40%, Dusty: false
[Action] Patrolling rooms... Battery at 25%
[BT] Root execution status: success

[Tick 6]
[State] Battery: 25%, Dusty: false
[Cond] Battery is low: 25%
[Action] Charging... Battery 25% -> 50% (running)
[BT] Root execution status: running

[Tick 7]
[State] Battery: 50%, Dusty: false
[Cond] Still charging
[Action] Charging... Battery 50% -> 75% (running)
[BT] Root execution status: running

[Tick 8]
[State] Battery: 75%, Dusty: false
[Cond] Still charging
[Action] Charging... Battery 75% -> 100% (success)
[BT] Root execution status: success

[Tick 9]
[State] Battery: 100%, Dusty: false
[Action] Patrolling rooms... Battery at 85%
[BT] Root execution status: success

[Tick 10]
[State] Battery: 85%, Dusty: false
[Action] Patrolling rooms... Battery at 70%
[BT] Root execution status: success

[Tick 11]
[State] Battery: 70%, Dusty: false
[Env] Dust has settled in the room.
[Action] Patrolling rooms... Battery at 55%
[BT] Root execution status: success

[Tick 12]
[State] Battery: 55%, Dusty: true
[Cond] Dust detected in room!
[Action] Cleaning dust... Battery at 45%
[BT] Root execution status: success
--- Simulation Completed ---
~~~~~~~~

Ticks 1 to 5 patrol, since neither condition holds. At tick 6 the battery is low, so the selector's first branch runs `recharge`, which returns `running`: the job takes more than one tick. At tick 7 the battery is 50%, no longer low, but `needs_charge` still holds because the robot remembers it is charging, so the recharge continues. Tick 8 finishes it. At tick 11 dust appears, and at tick 12 the second branch cleans it.

## Key Design Decisions

**State in dynamic facts.** The robot's state (`battery/1`, `dusty/1`, `charging/0`) lives in dynamic facts. Conditions and actions read and change it directly, so the engine need not pass a state value through every node.

**Trees as terms.** Behavior trees are often written in JSON or XML, or drawn in an editor. In Prolog a tree is a term such as `selector([sequence([condition(A), action(B)]), action(C)])`, so it needs no parser, and a program can build or change trees as data.

**Repeatable runs.** The simulation seeds the random number generator, so every run gives the same trace, and the tests in **tests/test_bt.pl** can check it. The tests also check each node type, including how `running` passes up through sequences and selectors.

## Optional Practice Problems

1. **An Inverter Node**: Add an `inverter(Child)` node that turns `success` into `failure` and the reverse, and passes `running` through. Add tests.
2. **Memory Sequence**: Add a `memory_sequence(Id, Children)` node that remembers which child was running (in a dynamic fact keyed by `Id`) and resumes there on the next tick. Use it to remove the `charging` fact from the robot.
3. **Two Rooms**: Give the robot two rooms, each of which can be dusty, and a `move_to(Room)` action. Change the tree so the robot cleans the dusty room nearest to it first.
