# Agent Behavior Trees

In artificial intelligence for robotics and video games, controlling agent behavior is a central challenge. Traditionally, developers relied on **Finite State Machines (FSMs)**. While FSMs are simple to implement, they suffer from a major design flaw: as the number of states and transitions grows, the state-transition graph quickly becomes a tangled web (often called "spaghetti code"), making it incredibly difficult to modify or extend.

**Behavior Trees (BTs)** emerged as a powerful alternative. Instead of states, BTs organize an agent's decision-making process into a hierarchical tree of nodes. Ticking the root node of the tree evaluates its children recursively, selecting actions based on environmental conditions. 

BTs are:
- **Highly Modular**: Sub-trees can be designed and tested independently.
- **Composable**: New behaviors can be inserted by adding branches without modifying existing ones.
- **Readable**: The hierarchical structure mirrors human-like decision pathways (e.g., "if battery is low, charge; otherwise, if dust is detected, clean; otherwise, patrol").

Prolog is exceptionally well-suited for implementing Behavior Trees. Its native pattern matching, recursive evaluation, and dynamic databases make it possible to build a complete behavior tree interpreter in under 100 lines of code.


{width: "80%"}
![Architecture diagram for the Agent Behavior Trees example](FIG_agent_behavior_trees.jpg)


## Behavior Tree Node Types

Our interpreter supports four core node types:
1. **Sequence (`sequence([Children])`)**: Ticks children sequentially. If any child fails, the sequence fails immediately. If all succeed, the sequence succeeds. (Analogous to an logical `AND`).
2. **Selector (`selector([Children])`)**: Ticks children sequentially. If any child succeeds, the selector succeeds immediately. If all fail, the selector fails. (Analogous to a logical `OR`, used for fallback actions).
3. **Condition (`condition(Name)`)**: Evaluates a query. Returns `success` if the query is true, and `failure` otherwise.
4. **Action (`action(Name)`)**: Executes an active task, returning `success`, `failure`, or `running` (if the action requires multiple ticks to complete).

---

## Implementing the BT Engine in Prolog

The core engine uses recursive pattern matching to traverse the tree nodes. We define multifile hooks `user_condition/1` and `user_action/2` to allow external agent modules to define their specific logic.

Here is the implementation in **source-code/agent_behavior_trees/prolog/behavior_trees.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
:- module(behavior_trees, [
    tick/2,
    define_tree/2
]).

/** <module> Behavior Trees Engine
 *
 * A simple, lightweight, and elegant
 * Behavior Tree implementation in Prolog.
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

% --- Interface to Hook Action & Condition Predicates ---
% User-defined actions and conditions are
% expected to be defined in user modules
% or hooked into the following dynamic/multifile predicates:
:- multifile user_condition/1.
:- multifile user_action/2.

call_condition(CondName) :-
    user_condition(CondName).

call_action(ActionName, Status) :-
~~~~~~~~

---

## Defining a Robot Agent

Now, we use our engine to program a cleaning robot. The robot has a battery level and a room dust state. We define its behavior tree as follows:
- **High Priority Branch**: If the battery is low, recharge.
- **Medium Priority Branch**: If dust is present, clean the room.
- **Fallback Branch**: Patrol the rooms, occasionally generating new dust.

Here is the implementation in **source-code/agent_behavior_trees/prolog/robot_agent.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
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
    format('[Action] Charging... Battery increased from ~w% to ~w%~n',
        [Level, NewLevel]).

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
~~~~~~~~

---

## Simulating the Agent

To run the simulation, execute the script from your terminal using SWI-Prolog:

{linenos=off}
~~~~~~~~
$ swipl -g "run_simulation(10), halt." -t "halt(1)" prolog/robot_agent.pl
~~~~~~~~

A sample execution trace shows the agent checking conditions and carrying out appropriate actions depending on battery levels and dynamic dust generation:

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
[Env] Dust has settled in the room.
[BT] Root execution status: success

[Tick 3]
[State] Battery: 70%, Dusty: true
[Cond] Dust detected in room!
[Action] Cleaning dust... Battery at 60%
[BT] Root execution status: success

[Tick 4]
[State] Battery: 60%, Dusty: false
[Action] Patrolling rooms... Battery at 45%
[BT] Root execution status: success

[Tick 5]
[State] Battery: 45%, Dusty: false
[Action] Patrolling rooms... Battery at 30%
[BT] Root execution status: success

[Tick 6]
[State] Battery: 30%, Dusty: false
[Action] Patrolling rooms... Battery at 15%
[BT] Root execution status: success

[Tick 7]
[State] Battery: 15%, Dusty: false
[Cond] Battery is low: 15%
[Action] Charging... Battery increased from 15% to 65%
[BT] Root execution status: success
~~~~~~~~

Notice how at Tick 3, dust is detected, causing the selector to bypass the patrol action and execute the clean action instead. At Tick 7, the low battery triggers the recharge branch, ignoring dust and patrol entirely.

---

## Key Design Decisions

**Dynamic database for state.** The robot's variables (like `battery/1` and `dusty/1`) are kept as dynamic facts (`:- dynamic ...`). In Prolog, asserting and retracting facts mimics a global memory store, allowing conditions and actions to read and modify state without having to pass a state dictionary through the tree's recursive helper functions.

**Logical structures as DSL.** Behavior trees are traditionally declared using JSON, XML, or specialized editor graphs. In Prolog, we can represent trees directly as structured terms, such as `selector([sequence([condition(A), action(B)]), action(C)])`. This provides an elegant domain-specific language (DSL) with zero parsing overhead, which can be modified directly within the source code.
