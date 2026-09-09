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

%% Moves: farmer always crosses, optionally carrying one item.
%% Each move is expressed once; opposite/2 supplies the two
%% directions, so only 4 rules are needed instead of 8.
move(state(From,F,C,G), state(To,F,C,G), farmer_alone) :-
    opposite(From, To).
move(state(From,From,C,G), state(To,To,C,G), farmer_fox) :-
    opposite(From, To).
move(state(From,F,From,G), state(To,F,To,G), farmer_chicken) :-
    opposite(From, To).
move(state(From,F,C,From), state(To,F,C,To), farmer_grain) :-
    opposite(From, To).

%% opposite(+Bank, -OtherBank) — the two river banks.
opposite(left, right).
opposite(right, left).

%% Safety: a state is unsafe when the fox and chicken (or chicken
%% and grain) share a bank while the farmer is on the opposite
%% bank.  Pure head-pattern matching via opposite/2 — no ==/2.
safe(State) :-
    \+ unsafe(State).

unsafe(state(Farmer, Bank, Bank, _)) :-
    opposite(Farmer, Bank).             % fox left with chicken
unsafe(state(Farmer, _, Bank, Bank)) :-
    opposite(Farmer, Bank).             % chicken left with grain
