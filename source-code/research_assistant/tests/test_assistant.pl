:- module(test_assistant, []).
:- use_module(library(plunit)).
:- use_module('../prolog/assistant').

:- begin_tests(assistant).

test(research_returns) :-
    research("What is Prolog?", Answer),
    nonvar(Answer).

:- end_tests(assistant).
