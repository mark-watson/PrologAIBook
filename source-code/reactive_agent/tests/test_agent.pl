:- module(test_agent, []).
:- use_module(library(plunit)).
:- use_module('../prolog/agent').
:- use_module('../prolog/vacuum_world').

:- begin_tests(agent, [cleanup(reset_agent)]).

actions(Actions) :-
    findall(A, action_log(_, A), Actions).

test(both_dirty_from_a) :-
    setup_world(a, [a, b]),
    with_output_to(string(_), run_agent(vacuum_world, 10)),
    actions(Actions),
    assertion(Actions == [suck, move_right, suck]),
    assertion(belief(all_clean)).

test(only_b_dirty_from_b) :-
    setup_world(b, [b]),
    with_output_to(string(_), run_agent(vacuum_world, 10)),
    actions(Actions),
    assertion(Actions == [suck, move_left]).

test(already_clean_rooms_still_checked) :-
    % The robot cannot see room b from room a, so it must look.
    setup_world(a, []),
    with_output_to(string(_), run_agent(vacuum_world, 10)),
    actions(Actions),
    assertion(Actions == [move_right]).

test(step_limit) :-
    setup_world(a, [a, b]),
    with_output_to(string(Out), run_agent(vacuum_world, 1)),
    assertion(sub_string(Out, _, _, _, "stopped after 1 steps")).

test(unknown_tool_is_error, [error(existence_error(tool, fly))]) :-
    reset_agent,
    agent:execute_action(1, fly).

:- end_tests(agent).
