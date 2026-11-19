:- module(test_rules, []).
:- use_module(library(plunit)).

% rules.pl has no module declaration (the browser consults it into
% user), so we load it into user here too.
:- user:consult('../rules.pl').

:- begin_tests(wasm_rules).

test(meat_any) :-
    findall(W, user:recommend(meat, any, any, W, _, _), Ws),
    assertion(Ws == [cabernet_sauvignon, merlot, pinot_noir, port]).

test(fish_dry) :-
    findall(W, user:recommend(fish, any, dry, W, _, _), Ws),
    assertion(Ws == [chardonnay, sauvignon_blanc]).

test(dessert_sweet_both_colors) :-
    findall(C-W, user:recommend(dessert, any, sweet, W, C, _), Ps),
    assertion(Ps == [white-riesling, white-moscato, red-port,
                     white-sauternes]).

test(explanation_text) :-
    once(user:recommend(fish, full_body, dry, _, _, E)),
    assertion(E == "A white wine is a classic pairing for fish. chardonnay is a full-bodied, dry white wine.").

test(no_match, [fail]) :-
    user:recommend(meat, light_body, sweet, _, _, _).

:- end_tests(wasm_rules).
