%% farmer.pl - Farmer, Fox, Chicken, Grain river crossing puzzle
%% Demonstrates state-space search with Prolog backtracking
:- module(farmer, [
    solve_farmer/1
]).

%% State: state(Farmer, Fox, Chicken, Grain) where each is 'left' or
%% 'right'
%% Goal: all on the right bank

solve_farmer(Moves) :-
    InitState = state(left, left, left, left),
    GoalState = state(right, right, right, right),
    solve(InitState, GoalState, [InitState], RevMoves),
    reverse(RevMoves, Moves).

solve(Goal, Goal, _Visited, []).
solve(State, Goal, Visited, [Description|Moves]) :-
    move(State, NextState, Description),
    safe(NextState),
    \+ member(NextState, Visited),
    solve(NextState, Goal, [NextState|Visited], Moves).

%% Moves: farmer always crosses, optionally carrying one item
move(state(left,F,C,G), state(right,F,C,G), farmer_alone).
move(state(right,F,C,G), state(left,F,C,G), farmer_alone).
move(state(left,left,C,G), state(right,right,C,G), farmer_fox).
move(state(right,right,C,G), state(left,left,C,G), farmer_fox).
move(state(left,F,left,G), state(right,F,right,G), farmer_chicken).
move(state(right,F,right,G), state(left,F,left,G), farmer_chicken).
move(state(left,F,C,left), state(right,F,C,right), farmer_grain).
move(state(right,F,C,right), state(left,F,C,left), farmer_grain).

%% Safety: fox cannot be alone with chicken, chicken cannot be alone
%% with grain
safe(state(Farmer, Fox, Chicken, Grain)) :-
    (Fox == Chicken -> Farmer == Fox ; true),
    (Chicken == Grain -> Farmer == Chicken ; true).
