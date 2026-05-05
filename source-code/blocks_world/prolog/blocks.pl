%% blocks.pl - Blocks World planner
:- module(blocks, [
    blocks_plan/3,
    print_state/1
]).

%% blocks_plan(+InitState, +GoalState, -Moves)
%% State is a list of on(X,Y) and on_table(X) atoms
blocks_plan(State, Goal, []) :-
    subset(Goal, State).
blocks_plan(State, Goal, [Move|Moves]) :-
    blocks_move(State, Move, NewState),
    \+ blocks_plan_visited(NewState),
    assert(blocks_plan_visited(NewState)),
    blocks_plan(NewState, Goal, Moves).

:- dynamic blocks_plan_visited/1.

blocks_move(State, move(X, table, To), NewState) :-
    member(on_table(X), State),
    clear(X, State),
    block_in_state(To, State),
    dif(X, To),
    clear(To, State),
    select(on_table(X), State, S1),
    NewState = [on(X, To)|S1].
blocks_move(State, move(X, From, To), NewState) :-
    member(on(X, From), State),
    clear(X, State),
    block_in_state(To, State),
    dif(X, To),
    clear(To, State),
    select(on(X, From), State, S1),
    NewState = [on(X, To)|S1].
blocks_move(State, move_to_table(X, From), NewState) :-
    member(on(X, From), State),
    clear(X, State),
    select(on(X, From), State, S1),
    NewState = [on_table(X)|S1].

block_in_state(B, State) :- member(on_table(B), State).
block_in_state(B, State) :- member(on(B, _), State).
block_in_state(B, State) :- member(on(_, B), State).

clear(X, State) :- \+ member(on(_, X), State).
clear(table, _).
on_something(X, Y, State) :- member(on(X, Y), State).
on_something(X, table, State) :- member(on_table(X), State).

%% print_state(+State) - Display a blocks world state
print_state(State) :-
    format("State: ~w~n", [State]).