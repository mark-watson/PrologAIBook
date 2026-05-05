:- module(test_wine, []).
:- use_module(library(plunit)).
:- use_module('../prolog/wine_rules').

:- begin_tests(wine).

test(red_meat_bold, [nondet]) :-
    recommend_wine(red_meat, bold, Wine),
    Wine == cabernet_sauvignon.

test(fish_light, [nondet]) :-
    recommend_wine(fish, light, Wine),
    memberchk(Wine, [sauvignon_blanc, riesling]).

:- end_tests(wine).
