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
forest_reward(_, 1, R1, R2, R) :-          % Cut
    R is (R1 + R2) / 2.0.                  % simplified average reward
                                           % for cutting
forest_reward(4, 0, R1, _, R1).            % Wait at max age
forest_reward(S, 0, _, _, 0.0) :- S < 4.  % Wait at younger age

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

% ============================================================
% Main entry point
% ============================================================

main :-
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
