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
        0).

train_loop(Ep, Total, _, _, _, _, _, Successes, _) :-
    Ep >= Total,





                        format("  Training complete. Total successes in last window tracked above.~n"),
    format("  Total episodes run: ~w~n", [Total]),
    _ = Successes.

train_loop(Ep, Total, Alpha, Gamma, Epsilon, EpsDecay, MinEps,
    WinSuccesses, WindowCount) :-
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
        ResetSuccesses = 0, ResetWindow = 0
    ;   ResetSuccesses = WinSuccesses1, ResetWindow = WindowCount1
    ),
    train_loop(Ep1, Total, Alpha, Gamma, NewEps, EpsDecay, MinEps,
               ResetSuccesses, ResetWindow).

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
