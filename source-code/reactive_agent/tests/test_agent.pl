:- module(test_agent, []).
:- use_module(library(plunit)).
:- use_module('../prolog/agent').

:- begin_tests(agent).

test(register_tool) :-
    register_tool(search, search_web/1).

test(define_goal) :-
    define_goal(answer_found).

:- end_tests(agent).
