:- module(test_assistant, []).
:- use_module(library(plunit)).
:- use_module('../prolog/assistant').

:- begin_tests(assistant).

% Stub test: the pipeline is not yet implemented, so this test is
% marked blocked rather than passing trivially.
test(research_returns,
     [blocked('pipeline not yet implemented')]) :-
    research("What is Prolog?", Answer),
    nonvar(Answer).

:- end_tests(assistant).
