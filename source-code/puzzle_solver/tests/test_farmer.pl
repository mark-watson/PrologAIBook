:- module(test_farmer, []).
:- use_module(library(plunit)).
:- use_module('../prolog/farmer').

:- begin_tests(farmer).

test(farmer_has_solution, [nondet]) :-
    solve_farmer(Moves),
    is_list(Moves),
    length(Moves, N),
    N > 0.

:- end_tests(farmer).
