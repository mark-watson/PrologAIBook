:- module(test_wine, []).
:- use_module(library(plunit)).
:- use_module('../prolog/wine_rules').

:- begin_tests(wine).

test(red_meat_bold, [nondet]) :-
    findall(W, recommend_wine(red_meat, bold, W), Wines),
    sort(Wines, Sorted),
    Sorted == [cabernet_sauvignon, port].

test(fish_light, [nondet]) :-
    recommend_wine(fish, light, Wine),
    memberchk(Wine, [sauvignon_blanc, riesling]).

test(dessert_sweet, [nondet]) :-
    findall(W, recommend_wine(dessert, sweet, W), Wines),
    sort(Wines, Sorted),
    Sorted == [port, riesling].

test(any_preference_lists_all_pairings) :-
    findall(W, recommend_wine(fish, any, W), Wines),
    sort(Wines, Sorted),
    assertion(Sorted == [champagne, chardonnay, riesling,
                         sauvignon_blanc]).

test(unknown_meal, [fail]) :-
    recommend_wine(cereal, any, _).

:- end_tests(wine).
