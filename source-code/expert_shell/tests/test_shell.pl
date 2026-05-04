:- module(test_shell, []).
:- use_module(library(plunit)).
:- use_module('../prolog/shell').

:- begin_tests(shell).

test(default_unknown) :-
    consult_expert(Conclusion),
    Conclusion == unknown.

:- end_tests(shell).
