# Reinforcement Learning in Prolog

Reinforcement learning studies agents that learn from reward. An agent acts in an environment, observes a new state and a scalar reward after each act, and adapts its behavior to raise the total reward it collects over time. No teacher hands the agent correct acts. The reward signal alone shapes what it learns.

This chapter covers two settings. In the first, the agent knows the rules of the world: how acts change the state and what reward each change pays. It can then plan with dynamic programming. In the second, the agent knows nothing about the world and must learn purely from trial and error. Both demos live in **source-code/reinforcement_learning** and run in pure SWI-Prolog with no outside libraries.

## Markov Decision Processes

A Markov decision process (MDP) gives the standard frame for the planning setting. An MDP has:

- a set of states `S`$,
- a set of acts `A`$,
- transition odds `P(s'|s,a)`$ that give the chance of landing in state `s'`$ after act `a`$ in state `s`$,
- a reward function `R(s,a)`$,
- a discount factor `\gamma`$ in `[0,1)`$ that weighs near rewards more than far ones.

A policy `\pi`$ maps each state to an act. The worth of a state under a policy is the mean discounted return the agent expects from that state on:

```$
V^\pi(s) = E\left[\sum_{t=0}^{\infty} \gamma^t r_t \mid s_0 = s, \pi\right].
```

The optimal worth function `V^*`$ obeys the Bellman optimality equation: the worth of a state equals the best act's instant reward plus the discounted worth of where that act leads:

```$
V^*(s) = \max_a \left[ R(s,a) + \gamma \sum_{s'} P(s'|s,a) V^*(s') \right].
```

Two classic methods solve this equation. Value iteration applies the Bellman update to all states at once and repeats until no worth shifts by more than a small bound. Policy iteration starts from a random policy, scores it exactly, then improves it to act greedily with respect to those scores, and repeats until the policy stops changing. The file **reinforcement_learning/mdp_demo.pl** codes both and runs them on two small worlds.

## Example 1: A Grid World Solved Two Ways

The first world is a 3x3 grid with states `0`$ to `8`$ in row-major order and four acts: `0`$ is up, `1`$ is right, `2`$ is down, `3`$ is left. Moves are exact: each act leads to the aimed cell with odds `1.0`$, and a move into a wall leaves the agent where it stands. State `8`$ is the goal and pays `+10`$. State `5`$ is a trap and pays `-5`$. All other states pay `0`$. Here is the head of the file with the world model:

```prolog
% Markov Decision Process (MDP) Demo in Prolog
% Demonstrates Value Iteration and Policy Iteration on:
%   Example 1: a hand-built 3x3 grid world
%   Example 2: a Forest Management problem
%
% References:
%   MDP: https://en.wikipedia.org/wiki/Markov_decision_process
%   Value Iteration:
%   https://en.wikipedia.org/wiki/Markov_decision_process#Value_iteration
%   Policy Iteration:
%   https://en.wikipedia.org/wiki/Markov_decision_process#Policy_iteration
%   Bellman equation: https://en.wikipedia.org/wiki/Bellman_equation
%
% Run with SWI-Prolog:
%   swipl -g main -t halt mdp_demo.pl

:- use_module(library(lists)).
:- use_module(library(apply)).

% ============================================================
% Utility helpers
% ============================================================

% argmax: index of maximum value in a list (0-based)
argmax(List, Idx) :-
    max_list(List, MaxVal),
    nth0(Idx, List, MaxVal), !.

% Absolute difference
abs_diff(A, B, D) :- D is abs(A - B).

% ============================================================
% Example 1: 3x3 Grid World
%
% States 0..8 in row-major order:
%   0 1 2
%   3 4 5
%   6 7 8
%
% Actions: 0=up(-1,0), 1=right(0,+1), 2=down(+1,0), 3=left(0,-1)
% Goal: state 8 (+10), Trap: state 5 (-5)
% ============================================================

% State index -> (Row, Col)
state_rc(S, R, C) :- R is S // 3, C is S mod 3.

% (Row, Col) -> State index
rc_state(R, C, S) :- S is R * 3 + C.

% Action deltas: action -> (DRow, DCol)
action_delta(0, -1, 0).   % up
action_delta(1,  0, 1).   % right
action_delta(2,  1, 0).   % down
action_delta(3,  0, -1).  % left

% Transition: transition(State, Action, NextState, Prob)
% Deterministic (Prob=1.0); wall bumps -> stay in same state
transition(S, A, NS, 1.0) :-
    state_rc(S, R, C),
    action_delta(A, DR, DC),
    NR is R + DR,
    NC is C + DC,
    ( NR >= 0, NR < 3, NC >= 0, NC < 3
    -> rc_state(NR, NC, NS)
    ;  NS = S
    ).

% Reward: reward(State, _Action, Reward)
reward(8, _, 10.0).   % goal cell
reward(5, _, -5.0).   % trap cell
reward(S, _, 0.0) :- S \= 8, S \= 5.
```

Facts state the world shape. `state_rc/3` and `rc_state/3` shift between a state index and its row and column. `transition/4` adds the act delta to the row and column and falls back to the same state at a wall. `reward/3` keys off the current state only, so goal and trap pay on entry and on every step spent there.

### Value Iteration

Value iteration keeps the worth function as a plain list of nine floats and sweeps the Bellman update over it until the largest single shift drops below a bound:

```prolog
% -----------------------------------------------
% Value Iteration
%
% Bellman optimality: V(s) = max_a [ R(s,a) + gamma * sum_{s'}
% P(s'|s,a)*V(s') ]
% -----------------------------------------------

% q_value(+State, +Action, +VList, +Gamma, -QValue)
% QValue for one (state, action) pair given current value function VList
q_value(S, A, VList, Gamma, QVal) :-
    transition(S, A, NS, Prob),
    reward(S, A, R),
    nth0(NS, VList, VNS),
    QVal is R + Gamma * Prob * VNS.

% best_action_value(+State, +VList, +Gamma, -BestQ, -BestA)
best_action_value(S, VList, Gamma, BestQ, BestA) :-
    numlist(0, 3, Actions),
    findall(QV-Ac,
            ( member(Ac, Actions),
              q_value(S, Ac, VList, Gamma, QV) ),
            Pairs),
    pairs_keys(Pairs, QVals),
    max_list(QVals, BestQ),
    member(BestQ-BestA, Pairs), !.

% one_vi_sweep(+OldV, +NStates, +Actions, +Gamma, -NewV, -MaxDelta)
one_vi_sweep(OldV, NStates, Gamma, NewV, MaxDelta) :-
    NStatesM1 is NStates - 1,
    numlist(0, NStatesM1, States),
    maplist(best_state_value(OldV, Gamma), States, NewV),
    maplist(abs_diff, OldV, NewV, Diffs),
    max_list(Diffs, MaxDelta).

best_state_value(VList, Gamma, S, BestQ) :-
    best_action_value(S, VList, Gamma, BestQ, _).

% value_iteration(+NStates, +Gamma, +Tol, -V, -Policy, -Iter)
value_iteration(NStates, Gamma, Tol, V, Policy, Iter) :-
    length(V0, NStates),
    maplist(=(0.0), V0),
    vi_loop(V0, NStates, Gamma, Tol, V, 0, Iter),
    extract_policy(V, NStates, Gamma, Policy).

vi_loop(V, NStates, Gamma, Tol, VFinal, I, IFinal) :-
    one_vi_sweep(V, NStates, Gamma, NewV, MaxDelta),
    I1 is I + 1,
    ( MaxDelta < Tol
    -> VFinal = NewV, IFinal = I1
    ;  vi_loop(NewV, NStates, Gamma, Tol, VFinal, I1, IFinal)
    ).

extract_policy(V, NStates, Gamma, Policy) :-
    NStatesM1 is NStates - 1,
    numlist(0, NStatesM1, States),
    maplist(best_action(V, Gamma), States, Policy).

best_action(VList, Gamma, S, BestA) :-
    best_action_value(S, VList, Gamma, _, BestA).
```

`q_value/5` scores one state-act pair from the current worth list. `best_action_value/5` builds all four pairs with `findall/3` and picks the max, which is the `\max_a`$ step of the Bellman equation. `one_vi_sweep/5` maps that max over all states with `maplist/3` and reports the worst shift. `vi_loop/7` recurses until the shift falls under `Tol`, and `extract_policy/4` reads the greedy policy off the final worth list. Note that `transition/4` here yields just one next state, so the sum over `s'`$ in the Bellman equation collapses to one term. The forest code below shows the full sum.

### Policy Iteration

Policy iteration keeps an explicit policy as a list of nine acts and alternates scoring it with improving it:

```prolog
% -----------------------------------------------
% Policy Iteration
% -----------------------------------------------

% policy_value(+State, +Policy, +VList, +Gamma, -Val)
policy_value(S, Policy, VList, Gamma, Val) :-
    nth0(S, Policy, A),
    q_value(S, A, VList, Gamma, Val).

% policy_evaluation: iterate V = R + gamma*P*V for current policy
eval_policy(Policy, NStates, Gamma, Tol, V) :-
    length(V0, NStates),
    maplist(=(0.0), V0),
    eval_loop(V0, Policy, NStates, Gamma, Tol, V).

eval_loop(V, Policy, NStates, Gamma, Tol, VFinal) :-
    NStatesM1 is NStates - 1,
    numlist(0, NStatesM1, States),
    maplist(policy_value_for_state(Policy, V, Gamma), States, NewV),
    maplist(abs_diff, V, NewV, Diffs),
    max_list(Diffs, MaxDelta),
    ( MaxDelta < Tol
    -> VFinal = NewV
    ;  eval_loop(NewV, Policy, NStates, Gamma, Tol, VFinal)
    ).

policy_value_for_state(Policy, VList, Gamma, S, Val) :-
    policy_value(S, Policy, VList, Gamma, Val).

% policy_iteration(+NStates, +Gamma, +Tol, -V, -Policy, -Iter)
policy_iteration(NStates, Gamma, Tol, V, Policy, Iter) :-
    % Start with policy: always take action 0 (up)
    length(P0, NStates),
    maplist(=(0), P0),
    pi_loop(P0, NStates, Gamma, Tol, V, Policy, 0, Iter).

pi_loop(Policy, NStates, Gamma, Tol, VFinal, PolicyFinal, I, IFinal) :-
    % Policy evaluation
    eval_policy(Policy, NStates, Gamma, Tol, V),
    % Policy improvement
    extract_policy(V, NStates, Gamma, NewPolicy),
    I1 is I + 1,
    ( NewPolicy == Policy
    -> VFinal = V, PolicyFinal = Policy, IFinal = I1
    ;  pi_loop(NewPolicy, NStates, Gamma, Tol, VFinal, PolicyFinal, I1,
        IFinal)
    ).

% Print a 3x3 grid policy using arrow characters
action_arrow(0, '^').
action_arrow(1, '>').
action_arrow(2, 'v').
action_arrow(3, '<').

print_grid_policy(Policy) :-
    forall(member(R, [0,1,2]),
           ( numlist(0, 2, Cols),
             maplist(print_cell(R, Policy), Cols),
             nl
           )).

print_cell(R, Policy, C) :-
    S is R * 3 + C,
    nth0(S, Policy, A),
    action_arrow(A, Arrow),
    format('  ~w  ', [Arrow]).
```

`eval_policy/5` scores the fixed policy by iterating `V = R + \gamma P V`$ to convergence. `pi_loop/8` then improves it with the same greedy `extract_policy/4` used above and halts when the policy no longer shifts (`NewPolicy == Policy`). Policy iteration runs few outer loops, since each improvement jumps straight to the greedy policy, but each loop pays for a full inner scoring run. `print_grid_policy/1` renders the result as a 3x3 arrow grid.

### Example 2: Forest Management

The second world in the same file is a forest stand with five age classes, states `0`$ to `4`$. Each year the agent picks Wait (`0`$) or Cut (`1`$). Fire strikes with odds `p = 0.1`$ and resets the age to `0`$. Cut at age `1`$ or more pays `R_1 = 4`$; Cut of a new stand pays `R_2 = 2`$; Wait pays `0`$ except at the top age, where Wait also pays `R_1`$. Unlike the grid, moves here are stochastic, so each act yields a list of next-state and odds pairs:

```prolog
% ============================================================
% Example 2: Forest Management MDP
%
% 5 states (forest age 0-4).
% Action 0 = Wait, Action 1 = Cut.
% Fire probability p = 0.1 each year (resets age to 0).
% Rewards: Cut age>=1 -> r1=4, Cut age=0 -> r2=2, Wait -> 0
%          except Wait at oldest age (4) gives r1=4.
% ============================================================

% forest_transition(+State, +Action, +FireP, -Transitions)
% Transitions = list of (NextState, Prob) pairs
forest_transition(S, 0, FireP, Trans) :-   % Wait
    S < 4,
    NS is S + 1,
    SurvP is 1.0 - FireP,
    Trans = [0-FireP, NS-SurvP].

forest_transition(4, 0, FireP, Trans) :-   % Wait at max age -> stay at
                                           % 4 (or fire)
    SurvP is 1.0 - FireP,
    Trans = [0-FireP, 4-SurvP].

forest_transition(_, 1, _, [0-1.0]).

% forest_reward(+State, +Action, +R1, +R2, -Reward)
% Age-dependent per the header comment: cutting at age >= 1 pays R1,
% cutting a brand-new forest (age 0) pays the lower R2.
forest_reward(S, 1, R1, _, R1) :- S >= 1.   % Cut at age >= 1
forest_reward(0, 1, _, R2, R2).             % Cut at age 0
forest_reward(4, 0, R1, _, R1).             % Wait at max age
forest_reward(S, 0, _, _, 0.0) :- S < 4.    % Wait at younger age

% forest_q_value(+S, +A, +VList, +Gamma, +FireP, +R1, +R2, -QVal)
forest_q_value(S, A, VList, Gamma, FireP, R1, R2, QVal) :-
    forest_reward(S, A, R1, R2, R),
    forest_transition(S, A, FireP, Trans),
    maplist(weighted_v(VList), Trans, WVals),
    sum_list(WVals, ExpV),
    QVal is R + Gamma * ExpV.

weighted_v(VList, NS-P, WV) :-
    nth0(NS, VList, V),
    WV is P * V.

% forest_best_value(+S, +VList, +Gamma, +FireP, +R1, +R2, -BestQ,
% -BestA)
forest_best_value(S, VList, Gamma, FireP, R1, R2, BestQ, BestA) :-
    findall(QV-Ac,
            ( member(Ac, [0,1]),
              forest_q_value(S, Ac, VList, Gamma, FireP, R1, R2, QV) ),
            Pairs),
    pairs_keys(Pairs, QVals),
    max_list(QVals, BestQ),
    member(BestQ-BestA, Pairs), !.

% forest_vi(+NStates, +Gamma, +Tol, +FireP, +R1, +R2, -V, -Policy,
% -Iter)
forest_vi(NStates, Gamma, Tol, FireP, R1, R2, V, Policy, Iter) :-
    length(V0, NStates),
    maplist(=(0.0), V0),
    forest_vi_loop(V0, NStates, Gamma, Tol, FireP, R1, R2, V, 0, Iter),
    NStatesM1 is NStates - 1,
    numlist(0, NStatesM1, States),
    maplist(forest_best_action(V, Gamma, FireP, R1, R2), States,
        Policy).

forest_vi_loop(V, NStates, Gamma, Tol, FireP, R1, R2, VFinal, I,
    IFinal) :-
    NStatesM1 is NStates - 1,
    numlist(0, NStatesM1, States),
    maplist(forest_best_state_value(V, Gamma, FireP, R1, R2), States,
        NewV),
    maplist(abs_diff, V, NewV, Diffs),
    max_list(Diffs, MaxDelta),
    I1 is I + 1,
    ( MaxDelta < Tol
    -> VFinal = NewV, IFinal = I1
    ;  forest_vi_loop(NewV, NStates, Gamma, Tol, FireP, R1, R2, VFinal,
        I1, IFinal)
    ).

forest_best_state_value(VList, Gamma, FireP, R1, R2, S, BestQ) :-
    forest_best_value(S, VList, Gamma, FireP, R1, R2, BestQ, _).

forest_best_action(VList, Gamma, FireP, R1, R2, S, BestA) :-
    forest_best_value(S, VList, Gamma, FireP, R1, R2, _, BestA).
```

`forest_q_value/8` codes the full Bellman backup: `weighted_v/3` weighs each next state's worth by its odds, and `sum_list/2` adds them into the mean future worth. The rest mirrors the grid solver: build both act pairs, take the max, sweep to convergence, then read off the greedy policy.

The `main/0` goal at the foot of the file runs all three solves in a row and prints each policy, worth function, and iteration count:

```prolog
% ============================================================
% Main entry point
% ============================================================

main :-
    % Seed for reproducibility (mdp_demo is deterministic, but other
    % files in this directory are not; keep the two consistent).
    set_random(seed(42)),
    nl,
    format("~`=t~55|~n"),
    format("Markov Decision Process Demo (Prolog)~n"),
    format("~`=t~55|~n"),

    % ---- Example 1: 3x3 Grid World ----
    nl,
    format("--- Example 1: Custom 3x3 Grid World ---~n"),
    NStates = 9,
    Gamma = 0.9,
    Tol = 1.0e-6,

    format("~nValue Iteration:~n"),
    value_iteration(NStates, Gamma, Tol, V, Policy, VIter),
    format("Optimal policy (grid):~n"),
    print_grid_policy(Policy),
    format("Value function:~n"),
    forall(nth0(S, V, Val), format("  V(~w) = ~4f~n", [S, Val])),
    format("Iterations to converge: ~w~n", [VIter]),

    format("~n--- Policy Iteration on same grid ---~n"),
    policy_iteration(NStates, Gamma, Tol, _VP, PIPolicy, PIter),
    format("Policy: ~w~n", [PIPolicy]),
    format("Iterations: ~w~n", [PIter]),

    % ---- Example 2: Forest Management ----
    nl,
    format("--- Example 2: Forest Management ---~n"),
    FNStates = 5, FireP = 0.1, R1 = 4.0, R2 = 2.0,
    format("States: ~w (forest age classes 0-~w)~n", [FNStates, 4]),
    format("Action 0 = Wait, Action 1 = Cut~n"),
    format("p(fire) = ~w each year~n", [FireP]),

    forest_vi(FNStates, Gamma, Tol, FireP, R1, R2, FV, FPolicy, FIter),
    format("~nOptimal policy:~n"),
    forall(nth0(S2, FPolicy, A2),
           ( ( A2 =:= 0 -> Act = 'Wait' ; Act = 'Cut' ),
             format("  Forest age ~w: ~w~n", [S2, Act]) )),
    format("Value function:~n"),
    forall(nth0(S3, FV, Val3), format("  V(~w) = ~4f~n", [S3, Val3])),
    format("Iterations: ~w~n", [FIter]).
```

Both solves use `\gamma = 0.9`$ and a bound of `10^{-6}`$. The grid runs value iteration first, then policy iteration on the same world so the reader can check that both reach the same policy. The forest runs value iteration with `p = 0.1`$ and prints the act picked for each age class.

## Example 3: Q-Learning on FrozenLake

Value and policy iteration need the world model: the odds `P`$ and rewards `R`$. Q-learning drops that need. It is model-free: the agent just acts, observes the reward and next state, and nudges one table entry per step. Given enough visits to each state-act pair, the table converges to the optimal act worths `Q^*`$.

Q-learning keeps a table `Q(s,a)`$ that scores each act in each state. Acts follow an epsilon-greedy rule: with odds `\epsilon`$ pick a random act to explore, else pick the act with the top Q worth to exploit. After each step that yields reward `r`$ and next state `s'`$, the agent applies the Q-learning update with step size `\alpha`$:

```$
Q(s,a) \leftarrow Q(s,a) + \alpha [r + \gamma \max_{a'} Q(s',a') - Q(s,a)].
```

The term in brackets is the temporal-difference error: the gap between the fresh one-step guess `r + \gamma \max_{a'} Q(s',a')`$ and the old score. Each update shrinks that gap by a factor of `\alpha`$. The file **reinforcement_learning/frozen_lake_qlearning.pl** trains such an agent on a 4x4 FrozenLake grid coded straight in Prolog, with no outside game library.

### The FrozenLake World

States are ints `0`$ to `15`$ in row-major order. Cells hold start (`s`), safe ice (`f`), holes (`h`, terminal, reward `0`$), and the goal (`g`, terminal, reward `1`$). Acts are `0`$ left, `1`$ down, `2`$ right, `3`$ up. Moves are exact: no slip, and wall bumps hold still.

```prolog
% Q-Learning on FrozenLake in Prolog
% Demonstrates model-free reinforcement learning using Q-learning on a
% 4x4 FrozenLake grid world implemented directly in Prolog.
%
% FrozenLake layout (S=start, F=frozen, H=hole, G=goal):
%   S F F F
%   F H F H
%   F F F H
%   H F F G
%
% Actions: 0=left, 1=down, 2=right, 3=up
%
% References:
%   Q-learning:  https://en.wikipedia.org/wiki/Q-learning
%   FrozenLake:
%   https://gymnasium.farama.org/environments/toy_text/frozen_lake/
%   TD learning:
%   https://en.wikipedia.org/wiki/Temporal_difference_learning
%
% Run with SWI-Prolog:
%   swipl -g main -t halt frozen_lake_qlearning.pl

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(random)).

% ============================================================
% FrozenLake Environment (4x4, deterministic — no slipping)
%
% State: integer 0..15, row-major (row*4 + col)
% ============================================================

% Cell types: s=start, f=frozen (safe), h=hole (terminal, -1), g=goal
% (terminal, +1)
cell_type(0,  s).
cell_type(1,  f).
cell_type(2,  f).
cell_type(3,  f).
cell_type(4,  f).
cell_type(5,  h).
cell_type(6,  f).
cell_type(7,  h).
cell_type(8,  f).
cell_type(9,  f).
cell_type(10, f).
cell_type(11, h).
cell_type(12, h).
cell_type(13, f).
cell_type(14, f).
cell_type(15, g).

% Is a state terminal (hole or goal)?
terminal(S) :- cell_type(S, h).
terminal(S) :- cell_type(S, g).

% Reward for landing in a state
state_reward(S, 1.0) :- cell_type(S, g), !.
state_reward(_, 0.0).

% Action deltas on a 4x4 grid: 0=left, 1=down, 2=right, 3=up
action_delta(0,  0, -1).   % left
action_delta(1,  1,  0).   % down
action_delta(2,  0,  1).   % right
action_delta(3, -1,  0).   % up

% step(+State, +Action, -NextState)
% Deterministic transition: bumping a wall keeps the agent in the same
% cell.
step(S, A, NS) :-
    R is S // 4,
    C is S mod 4,
    action_delta(A, DR, DC),
    NR is R + DR,
    NC is C + DC,
    ( NR >= 0, NR < 4, NC >= 0, NC < 4
    -> NS is NR * 4 + NC
    ;  NS = S
    ).
```

`cell_type/2` facts draw the map. `terminal/1` marks holes and the goal. `state_reward/2` pays `1.0`$ only for the goal, so the agent gets no hints along the way: a sparse reward task. `step/3` mirrors the grid `transition/4` from the MDP demo, scaled to 4x4.

### The Q-Table

The Q-table is a list of sixteen rows of four floats. It lives in a global var through `nb_setval/2` and `nb_getval/2`, since Prolog vars do not update in place and threading the table through each step would add noise:

```prolog
% ============================================================
% Q-Table: stored as a global mutable array via nb_getval/nb_setval
% Represented as a list of 16 sub-lists, each of length 4.
% ============================================================

% Initialize Q-table: 16 states x 4 actions, all zeros
init_qtable :-
    length(QRow, 4),
    maplist(=(0.0), QRow),
    length(Q, 16),
    maplist(=(QRow), Q),
    nb_setval(qtable, Q).

% get_q(+State, +Action, -QVal)
get_q(S, A, QVal) :-
    nb_getval(qtable, Q),
    nth0(S, Q, Row),
    nth0(A, Row, QVal).

% set_q(+State, +Action, +NewQVal)
set_q(S, A, NewQ) :-
    nb_getval(qtable, Q),
    nth0(S, Q, OldRow, RestQ),
    nth0(A, OldRow, _, RestRow),
    nth0(A, NewRow, NewQ, RestRow),
    nth0(S, NewQ2, NewRow, RestQ),
    nb_setval(qtable, NewQ2).

% best_q(+State, -BestQVal, -BestAction)
best_q(S, BestQ, BestA) :-
    nb_getval(qtable, Q),
    nth0(S, Q, Row),
    max_row(Row, BestQ, BestA).

max_row(Row, BestQ, BestA) :-
    max_list(Row, BestQ),
    nth0(BestA, Row, BestQ), !.
```

`init_qtable/0` builds the 16x4 zero table. `get_q/3` reads one cell with `nth0/3`. `set_q/3` uses the four-arg form of `nth0/4` twice: once to split the old row out of the table, once to split the old cell out of the row, then rebuilds both and stores the new table. `best_q/3` finds the top worth and its act in a row.

### Act Choice and the Q Update

```prolog
% ============================================================
% Epsilon-greedy action selection
% ============================================================

choose_action(S, Epsilon, A) :-
    random(R),
    ( R < Epsilon
    -> random_between(0, 3, A)           % explore: random action
    ;  best_q(S, _, A)                   % exploit: greedy action
    ).

% ============================================================
% Q-learning update
%   Q(s,a) <- Q(s,a) + alpha * [r + gamma * max_a' Q(s',a') - Q(s,a)]
% ============================================================

q_update(S, A, NS, Reward, Alpha, Gamma) :-
    get_q(S, A, OldQ),
    best_q(NS, MaxNextQ, _),
    NewQ is OldQ + Alpha * (Reward + Gamma * MaxNextQ - OldQ),
    set_q(S, A, NewQ).
```

`choose_action/3` draws a uniform float and explores when it falls under `\epsilon`$. `q_update/6` codes the update rule line for line: read the old score, read the best next score, form the temporal-difference error, and write back the nudged worth.

### Episodes and Training

```prolog
% ============================================================
% Run a single episode
% Result: success (1) or failure (0)
% ============================================================

run_episode(Alpha, Gamma, Epsilon, Result) :-
    run_step(0, Alpha, Gamma, Epsilon, Result).

run_step(S, Alpha, Gamma, Epsilon, Result) :-
    ( terminal(S)
    ->  % determine result from terminal state
        ( cell_type(S, g) -> Result = 1 ; Result = 0 )
    ;   choose_action(S, Epsilon, A),
        step(S, A, NS),
        state_reward(NS, R),
        q_update(S, A, NS, R, Alpha, Gamma),
        run_step(NS, Alpha, Gamma, Epsilon, Result)
    ).

% ============================================================
% Training loop
% ============================================================

% Epsilon decay: new_epsilon(+Eps, +Decay, +MinEps, -NewEps)
new_epsilon(Eps, Decay, MinEps, NewEps) :-
    E is Eps * Decay,
    NewEps is max(MinEps, E).

% train(+Episodes, +Alpha, +Gamma, +Epsilon, +EpsDecay, +MinEps)
train(Episodes, Alpha, Gamma, Epsilon, EpsDecay, MinEps) :-
    train_loop(0, Episodes, Alpha, Gamma, Epsilon, EpsDecay, MinEps, 0,
        0, 0).

% train_loop/10 carries TotalSuccesses (cumulative across the whole
% run) in addition to the per-window counters used for the periodic
% log line; the previously discarded Successes accumulator is gone.
train_loop(Ep, Total, _, _, _, _, _, WinSuccesses, _WindowCount,
    TotalSuccesses) :-
    Ep >= Total,
    TotalSuccesses1 is TotalSuccesses + WinSuccesses,
    format("  Training complete. Cumulative successes over ~w episodes: ~w~n",
           [Total, TotalSuccesses1]),
    format("  Total episodes run: ~w~n", [Total]).

train_loop(Ep, Total, Alpha, Gamma, Epsilon, EpsDecay, MinEps,
    WinSuccesses, WindowCount, TotalSuccesses) :-
    Ep < Total,
    run_episode(Alpha, Gamma, Epsilon, Result),
    new_epsilon(Epsilon, EpsDecay, MinEps, NewEps),
    Ep1 is Ep + 1,
    WinSuccesses1 is WinSuccesses + Result,
    WindowCount1 is WindowCount + 1,
    % Log every 1000 episodes
    ( Ep1 mod 1000 =:= 0
    ->  Rate is WinSuccesses1 / WindowCount1,
        format("  Episode ~5|~w: success rate = ~4f  (epsilon=~4f)~n",
               [Ep1, Rate, NewEps]),
        TotalSuccesses1 is TotalSuccesses + WinSuccesses1,
        ResetSuccesses = 0, ResetWindow = 0
    ;   TotalSuccesses1 = TotalSuccesses,
        ResetSuccesses = WinSuccesses1, ResetWindow = WindowCount1
    ),
    train_loop(Ep1, Total, Alpha, Gamma, NewEps, EpsDecay, MinEps,
               ResetSuccesses, ResetWindow, TotalSuccesses1).
```

Each episode starts at state `0`$ and recurses through `run_step/5` until it hits a hole or the goal. `train_loop/10` runs the set count of episodes, decays `\epsilon`$ after each one down to a floor, and logs the success rate over each block of 1000 episodes plus a final cumulative count. Decay matters: early episodes explore hard while the table is blank, and late episodes exploit the learned scores.

### Scoring, Policy Print, and Main

```prolog
% ============================================================
% Evaluate learned policy (greedy, no exploration)
% ============================================================

evaluate(EvalEpisodes, SuccessRate) :-
    evaluate_loop(0, EvalEpisodes, 0, Successes),
    SuccessRate is Successes / EvalEpisodes.

evaluate_loop(N, Total, Acc, Acc) :- N >= Total, !.
evaluate_loop(N, Total, Acc, Successes) :-
    N < Total,
    eval_episode(Result),
    Acc1 is Acc + Result,
    N1 is N + 1,
    evaluate_loop(N1, Total, Acc1, Successes).

eval_episode(Result) :- eval_step(0, Result).

eval_step(S, Result) :-
    ( terminal(S)
    ->  ( cell_type(S, g) -> Result = 1 ; Result = 0 )
    ;   best_q(S, _, A),
        step(S, A, NS),
        eval_step(NS, Result)
    ).

% ============================================================
% Print policy as a 4x4 grid of arrows
% ============================================================

action_arrow(0, '<').
action_arrow(1, 'v').
action_arrow(2, '>').
action_arrow(3, '^').

print_policy :-
    format("~nLearned policy (4x4 grid):~n"),
    forall(member(R, [0,1,2,3]),
           ( forall(member(C, [0,1,2,3]),
                    ( S is R * 4 + C,
                      ( cell_type(S, h) -> format(' H ')
                      ; cell_type(S, g) -> format(' G ')
                      ; best_q(S, _, A),
                        action_arrow(A, Arrow),
                        format(' ~w ', [Arrow])
                      )
                    )),
             nl
           )),
    format("  (< =left  v =down  > =right  ^ =up)~n").

% ============================================================
% Main entry point
% ============================================================

main :-
    % Seed the random number generator for reproducibility
    set_random(seed(42)),

    nl,
    format("~`=t~55|~n"),
    format("Q-Learning on FrozenLake (Prolog, deterministic)~n"),
    format("~`=t~55|~n"),
    format("States: 16  (4x4 grid)~n"),
    format("Actions: 4  (left/down/right/up)~n"),
    format("~nMap layout (S=start F=frozen H=hole G=goal):~n"),
    format("  S F F F~n"),
    format("  F H F H~n"),
    format("  F F F H~n"),
    format("  H F F G~n"),

    % Hyperparameters
    Episodes   = 5000,
    Alpha      = 0.1,
    Gamma      = 0.99,
    Epsilon    = 1.0,
    EpsDecay   = 0.999,
    MinEps     = 0.01,
    EvalEps    = 500,

    format("~nHyperparameters:~n"),
    format("  episodes=~w  alpha=~w  gamma=~w~n", [Episodes, Alpha,
        Gamma]),
    format("  epsilon=~w  decay=~w  min_eps=~w~n", [Epsilon, EpsDecay,
        MinEps]),

    init_qtable,

    format("~nTraining:~n"),
    train(Episodes, Alpha, Gamma, Epsilon, EpsDecay, MinEps),

    print_policy,

    format("~nFinal evaluation (~w episodes):~n", [EvalEps]),
    evaluate(EvalEps, Rate),
    format("  Success rate: ~4f~n", [Rate]),
    nl.
```

`evaluate/2` runs 500 fresh episodes with pure greedy acts (`best_q/3`, no `\epsilon`$) and reports the share that reach the goal. This score tests the learned policy itself, free of training noise. `print_policy/0` draws the greedy act in each safe cell as an arrow and marks holes and the goal. `main/0` seeds the random source for repeat runs, trains 5000 episodes with `\alpha = 0.1`$, `\gamma = 0.99`$, and `\epsilon`$ decaying from `1.0`$ by `0.999`$ per episode down to `0.01`$, then prints the policy and the final score.

## Running the Code

Both demos need SWI-Prolog (`swipl`) and nothing else. From the **source-code/reinforcement_learning** dir, run each file straight or use the Makefile:

```bash
swipl -g main -t halt mdp_demo.pl
swipl -g main -t halt frozen_lake_qlearning.pl
```

or:

```bash
make run
```

The MDP demo prints a banner, then the grid results: the value iteration policy as a 3x3 arrow grid, the full worth function `V(0)`$ through `V(8)`$, and the count of sweeps to converge; then the policy iteration result as a raw act list plus its outer loop count. Last comes the forest block: the Wait or Cut pick for each age class, the five worths, and the iteration count.

The Q-learning demo prints a banner with the map and settings, then one log line per 1000 training episodes with the block success rate and current `\epsilon`$, then a cumulative success count, then the learned policy as a 4x4 arrow grid with holes and the goal marked, and last the greedy success rate over 500 fresh episodes.

The dir also ships a plunit suite, **tests/test_rl.pl**, that checks a hand-computed Q update (`Q(0,2)`$ must equal `0.396`$ after one Bellman step against a preset table), goal and hole endings of `eval_step/2`, forest odds that sum to `1.0`$ for each state-act pair, age-based cut rewards, and a short 20-episode training run. Run it with:

```bash
make test
```

## Interpreting the Results

Read the MDP output as answers to "what is each state worth, and what should the agent do there?" Each `V(s)`$ is the mean discounted return from `s`$ under optimal play. States near the goal score high, since `\gamma = 0.9`$ still lets most of the `+10`$ survive a few steps of delay, while states near the trap score low, since the `-5`$ taints them. The arrow grid should point each cell toward the goal along a path that skirts the trap. Value iteration reaches this by slow backup sweeps, while policy iteration jumps between whole policies; both must print the same grid, which serves as a cross-check that each solver works.

The forest output answers a real trade question: cut now for sure cash, or wait for a bigger stand while risking fire. Each age class gets its own ruling, and the worths show what the stand is worth at each age under optimal care. Raise the fire odds and waiting grows dear; lower the discount and far payoffs fade. The demo fixes `p = 0.1`$ and `\gamma = 0.9`$, but the code takes all of these as args, so the reader can probe these shifts with one-line edits to `main/0`.

Read the Q-learning output as a learning curve. The per-1000-episode rates start near zero while `\epsilon`$ stays high and the table stays flat, then climb as decay shifts the mix toward greedy acts backed by real scores. The last greedy score over 500 episodes is the key gauge: it says how often the frozen policy reaches the goal with no random acts at all. The arrow grid shows what the agent learned: safe cells should point along a hole-free path from the start to the goal. If a run scores poorly, the first fix is more episodes or slower decay, since the sparse `1.0`$ at the goal alone must back up across the whole grid one step at a time.

## Wrap Up

This chapter built the two poles of reinforcement learning in Prolog. With a known model, value iteration and policy iteration solve the Bellman equation straight: the grid world showed exact moves, and the forest showed stochastic moves with a full odds-weighted backup. With no model, Q-learning learns the same kind of policy from raw trial episodes, backed by an epsilon-greedy rule and a global Q-table held in `nb_setval/2`. All three solvers share one core idiom: small Prolog goals (`q_value/5`, `forest_q_value/8`, `q_update/6`) that code a Bellman backup, driven by `maplist/3`, `findall/3`, and plain recursion. That idiom scales: swap the world facts and the backup goal, and the same loops solve new tasks.

## Optional Practice Problems

1. **Slippery grid**: Change `transition/4` in **mdp_demo.pl** so each act slips to a random side cell with odds `0.1`$. Return a list of next-state and odds pairs as in the forest code, widen `q_value/5` to sum over them, and compare the new optimal policy with the exact-move one.
2. **Slippery lake**: Add slip to `step/3` in **frozen_lake_qlearning.pl** (for instance, with odds `0.2`$ the agent slides to a random neighbor). Retrain and report how the final greedy success rate shifts. Does slower epsilon decay win back the loss?
3. **SARSA**: Turn the learner on-policy. In `run_step/5`, pick the next act before the update and change `q_update/6` to use that act's Q worth at the next state rather than the max. Compare its learning curve and final score with Q-learning.
4. **Cut age probe**: Call `forest_vi/9` with fire odds in `{0.0, 0.1, 0.3}`$ and discounts in `{0.5, 0.9, 0.99}`$. Tabulate how the Wait or Cut picks per age class move, and state in one line for each shift why the change makes sense.
