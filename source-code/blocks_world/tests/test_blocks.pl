:- module(test_blocks, []).
:- use_module(library(plunit)).
:- use_module('../prolog/blocks').

:- begin_tests(blocks_world).

test(already_solved) :-
    State = [on(a, b), on_table(b)],
    Goal = [on(a, b)],
    blocks_plan(State, Goal, Plan),
    Plan == [].

:- end_tests(blocks_world).
