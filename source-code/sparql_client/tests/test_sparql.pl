:- module(test_sparql, []).
:- use_module(library(plunit)).
:- use_module('../prolog/sparql').

:- begin_tests(sparql).

test(module_loads) :-
    true.  % Module loads; live queries tested manually

:- end_tests(sparql).
