:- module(test_bt, []).
:- use_module(library(plunit)).
:- use_module('../prolog/behavior_trees').

% Test conditions and actions, added to the engine's hooks.
:- multifile behavior_trees:user_condition/1, behavior_trees:user_action/2.

behavior_trees:user_condition(t_true).
behavior_trees:user_action(t_ok, success).
behavior_trees:user_action(t_fail, failure).
behavior_trees:user_action(t_wait, running).
behavior_trees:user_action(t_bad, maybe).

status(Tree, Status) :-
    define_tree(t, Tree),
    tick(t, Status).

:- begin_tests(behavior_trees).

test(sequence_all_succeed) :-
    status(sequence([condition(t_true), action(t_ok)]), S),
    assertion(S == success).

test(sequence_stops_at_failure) :-
    status(sequence([action(t_fail), action(t_bad)]), S),
    % t_bad is never ticked, so no error is raised.
    assertion(S == failure).

test(sequence_running) :-
    status(sequence([action(t_ok), action(t_wait), action(t_ok)]), S),
    assertion(S == running).

test(selector_first_success) :-
    status(selector([action(t_fail), action(t_ok)]), S),
    assertion(S == success).

test(selector_all_fail) :-
    status(selector([condition(t_unknown), action(t_fail)]), S),
    assertion(S == failure).

test(selector_running) :-
    status(selector([action(t_fail), action(t_wait)]), S),
    assertion(S == running).

test(undefined_action_error,
     [error(existence_error(bt_action, nope))]) :-
    status(action(nope), _).

test(bad_status_error, [error(type_error(_, maybe))]) :-
    status(action(t_bad), _).

:- end_tests(behavior_trees).

:- use_module('../prolog/robot_agent').

:- begin_tests(robot_agent).

test(simulation_is_repeatable) :-
    with_output_to(string(A), run_simulation(12)),
    with_output_to(string(B), run_simulation(12)),
    assertion(A == B).

test(charging_takes_several_ticks) :-
    with_output_to(string(Out), run_simulation(8)),
    assertion(sub_string(Out, _, _, _, "(running)")),
    assertion(sub_string(Out, _, _, _, "Still charging")).

:- end_tests(robot_agent).
