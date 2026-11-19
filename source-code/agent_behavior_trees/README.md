# Agent Behavior Trees in Prolog

This project implements a lightweight and modular **Behavior Tree (BT) engine** in Prolog, demonstrating how to use BTs to control agent decision-making.

## Why This Project is Useful
Behavior Trees (BTs) are a standard control architecture in game AI and robotics. They organize decision-making hierarchically, making agent behavior highly modular, readable, and easy to debug compared to traditional Finite State Machines (FSMs).

Prolog's pattern matching, backtracking, and dynamic databases make it an ideal language for:
1. **Defining a DSL (Domain-Specific Language)** to declare tree nodes (`sequence`, `selector`, `action`, `condition`).
2. **Evaluating the tree structure** using recursive pattern matching.
3. **Representing and updating agent state** naturally using dynamic predicates.

This project shows how to construct a generic behavior tree interpreter in about 100 lines of Prolog and use it to drive a stateful cleaning robot agent.

## Tools & Libraries Used
- **SWI-Prolog**: No external libraries are needed, as the tree interpreter is built using core Prolog features.

## Project Architecture
The Behavior Tree consists of a root node that is "ticked" at regular intervals. The nodes evaluate their children recursively:

![Behavior Trees Architecture](architecture.jpg)

## How to Run the Example

```bash
make run     # 12 ticks of the robot simulation
make test    # unit tests for the engine and the robot
```

The simulation sets a fixed random seed, so every run prints the same trace.

### Expected Output
The output will show a tick-by-tick trace of the robot's battery state, environment, which conditions were evaluated, which actions were executed, and the final state:

```text
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
```

Recharging takes several ticks, so the `recharge` action returns `running` until the battery reaches 80%.
