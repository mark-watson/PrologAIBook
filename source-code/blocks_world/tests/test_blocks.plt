:- module(test_blocks, []).
:- use_module(library(plunit)).
:- use_module(library(lists), [subset/2]).
:- use_module('../prolog/blocks').

:- begin_tests(blocks_world).

test(already_solved) :-
    State = [on(a, b), on_table(b)],
    Goal = [on(a, b)],
    blocks_plan(State, Goal, Plan),
    Plan == [].

test(build_tower_from_flat, [nondet]) :-
    % Multi-step plan: build a 1-tower from a flat start.
    State = [on_table(a), on_table(b)],
    Goal = [on(a, b)],
    blocks_plan(State, Goal, Plan),
    length(Plan, Len),
    Len > 0,
    % the plan really achieves the goal when simulated
    simulate(State, Plan, Final),
    subset(Goal, Final).

test(idempotent_successive_calls, [nondet]) :-
    % Two identical calls in one session must return the same
    % result (no leaked visited state between calls).
    State = [on_table(a), on_table(b)],
    Goal = [on(a, b)],
    blocks_plan(State, Goal, Plan1),
    blocks_plan(State, Goal, Plan2),
    Plan1 == Plan2.

test(unsolvable_goal_fails, [fail]) :-
    % A block cannot be on itself.
    blocks_plan([on_table(a)], [on(a, a)], _).

test(blocks_move_unit, [nondet]) :-
    % Moving a clear block onto a clear block.
    blocks:blocks_move([on_table(a), on_table(b)], Move, NewState),
    Move = move(a, table, b),
    member(on(a, b), NewState),
    \+ member(on_table(a), NewState).

test(blocks_move_to_table_unit, [nondet]) :-
    blocks:blocks_move([on(a, b), on_table(b)], Move, NewState),
    Move = move_to_table(a, b),
    member(on_table(a), NewState),
    \+ member(on(a, b), NewState).

:- end_tests(blocks_world).

%% simulate(+State, +Plan, -FinalState)
%% Apply each move in Plan with blocks:blocks_move/3.
simulate(State, [], State).
simulate(State, [Move|Plan], Final) :-
    blocks:blocks_move(State, Move, State1),
    simulate(State1, Plan, Final).
