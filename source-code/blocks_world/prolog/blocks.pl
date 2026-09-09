%% blocks.pl - Blocks World planner
:- module(blocks, [
    blocks_plan/3,
    print_state/1
]).

:- use_module(library(lists), [subset/2]).

:- dynamic blocks_plan_visited/1.

%% blocks_plan(+InitState, +GoalState, -Moves)
%% State is a list of on(X,Y) and on_table(X) atoms; clear/2 is a
%% derived relation (not stored in the state).  The visited set is
%% cleared on entry and exit (and on failure) via
%% setup_call_cleanup/3, so successive calls behave identically.
blocks_plan(State, Goal, Moves) :-
    setup_call_cleanup(
        retractall(blocks_plan_visited(_)),
        blocks_plan_dfs(State, Goal, Moves),
        retractall(blocks_plan_visited(_))
    ).

blocks_plan_dfs(State, Goal, []) :-
    subset(Goal, State), !.
blocks_plan_dfs(State, Goal, [Move|Moves]) :-
    blocks_move(State, Move, NewState),
    \+ blocks_plan_visited(NewState),
    assert(blocks_plan_visited(NewState)),
    blocks_plan_dfs(NewState, Goal, Moves).

%% blocks_move(+State, -Move, -NewState)
%% Moving a block X onto block To is the same whether X starts on
%% the table or on another block; only the source fact differs.
%% This shared rule merges the old duplicated clause pair.
blocks_move(State, move(X, From, To), NewState) :-
    from_fact(State, X, From, FromFact),
    clear(X, State),
    block_in_state(To, State),
    dif(X, To),
    clear(To, State),
    select(FromFact, State, S1),
    NewState = [on(X, To)|S1].
blocks_move(State, move_to_table(X, From), NewState) :-
    member(on(X, From), State),
    clear(X, State),
    select(on(X, From), State, S1),
    NewState = [on_table(X)|S1].

%% from_fact(+State, +X, -From, -Fact)
%% Where X currently sits: on the table, or on another block.
from_fact(State, X, table, on_table(X)) :- member(on_table(X), State).
from_fact(State, X, From,  on(X, From)) :- member(on(X, From), State).

block_in_state(B, State) :- member(on_table(B), State).
block_in_state(B, State) :- member(on(B, _), State).
block_in_state(B, State) :- member(on(_, B), State).

clear(X, State) :- \+ member(on(_, X), State).

%% print_state(+State) - Display a blocks world state
print_state(State) :-
    format("State: ~w~n", [State]).
