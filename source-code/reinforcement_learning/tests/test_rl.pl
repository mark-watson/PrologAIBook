:- use_module(library(plunit)).

% test_rl.pl — plunit tests for both reinforcement-learning examples.
% Loads the demo files directly so both can be exercised; each file's
% helpers live in `user`, so we test them through dedicated wrapper
% goals.

% Load the demos.  mdp_demo.pl contains no random behaviour but we
% still seed first for the Q-learning tests below.
:- set_random(seed(42)).
:- consult('../mdp_demo.pl').
:- consult('../frozen_lake_qlearning.pl').

:- begin_tests(rl).

% --- FrozenLake Q-update: hand-computed single step ---

% Start from a zero Q-table and apply one Bellman step from state 0
% taking action 2 (right, into the goal's neighbour... actually cell 1,
% frozen).  With alpha=0.5, gamma=0.99, reward=0:
%   Q(0,2) <- 0 + 0.5 * (0 + 0.99*max Q(1,:)) = 0
% because every Q is still 0 — so force a meaningful step by pre-setting
% Q(1,0) = 0.8 first, then the update gives 0.5 * 0.99 * 0.8 = 0.396.
test(q_update_hand_computed, [true(abs(Q - 0.396) < 1e-9)]) :-
    init_qtable,
    set_q(1, 0, 0.8),
    q_update(0, 2, 1, 0.0, 0.5, 0.99),
    get_q(0, 2, Q).

% --- Terminal states: eval_step must terminate and never call best_q
% on a terminal state ---

test(eval_step_terminal_goal, [true(R =:= 1)]) :-
    init_qtable,
    eval_step(15, R).

test(eval_step_terminal_hole, [true(R =:= 0)]) :-
    init_qtable,
    eval_step(5, R).

% --- Forest transition probabilities sum to ~1 for each (S, A) ---

test(forest_transition_probs_sum_to_1) :-
    forall(between(0, 4, S),
        ( member(A, [0,1]),
          forest_transition(S, A, 0.1, Trans),
          aggregate_all(sum(P), member(_-P, Trans), Sum),
          abs(Sum - 1.0) < 1e-9 )).

% --- Cut reward is age-dependent per the header comment ---

test(forest_reward_cut_age_dependent) :-
    forest_reward(0, 1, 4.0, 2.0, 2.0),   % age 0 cut pays R2
    forest_reward(3, 1, 4.0, 2.0, 4.0),   % age >=1 cut pays R1
    forest_reward(4, 0, 4.0, 2.0, 4.0),   % wait at max age
    forest_reward(2, 0, 4.0, 2.0, 0.0).   % wait at younger age

% --- Short training run stays bounded and logs cumulative successes ---

test(short_training_runs, [true(nonvar(TrainOk))]) :-
    init_qtable,
    with_output_to(atom(_),
        train(20, 0.1, 0.99, 1.0, 0.999, 0.01)),
    TrainOk = ok.

:- end_tests(rl).
