:- module(test_rdf, []).
:- use_module(library(plunit)).
:- use_module('../prolog/rdf_loader').

:- begin_tests(rdf_loader).

%% TBD: Add tests with sample Turtle files
test(module_loads) :-
    true.  % Module loads without error

:- end_tests(rdf_loader).
