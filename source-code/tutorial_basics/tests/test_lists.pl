:- module(test_lists, []).
:- use_module(library(plunit)).
:- use_module('../prolog/lists').

:- begin_tests(lists).

test(length_empty) :-
    my_length([], 0).

test(length_three) :-
    my_length([a, b, c], 3).

test(member_found) :-
    my_member(b, [a, b, c]).

test(member_not_found, [fail]) :-
    my_member(x, [a, b, c]).

test(append_lists) :-
    my_append([1, 2], [3, 4], [1, 2, 3, 4]).

test(reverse_list) :-
    my_reverse([1, 2, 3], [3, 2, 1]).

test(last_element) :-
    my_last([a, b, c], c).

:- end_tests(lists).
