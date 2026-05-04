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

blocks_move(State, move(X, From, To), NewState) :-
    clear(X, State),
    on_something(X, From, State),
    clear(To, State),
    X \= To,
    select(on(X, From), State, S1),
    NewState = [on(X, To)|S1].
blocks_move(State, move_to_table(X, From), NewState) :-
    clear(X, State),
    on_something(X, From, State),
    From \= table,
    select(on(X, From), State, S1),
    NewState = [on_table(X)|S1].

clear(X, State) :- \+ member(on(_, X), State).
clear(table, _).
on_something(X, Y, State) :- member(on(X, Y), State).
on_something(X, table, State) :- member(on_table(X), State).

%% print_state(+State) - Display a blocks world state
print_state(State) :-
    format("State: ~w~n", [State]).
