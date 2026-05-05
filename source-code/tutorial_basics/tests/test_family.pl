:- module(test_family, []).
:- use_module(library(plunit)).
:- use_module('../prolog/family').

:- begin_tests(family).

test(parent_direct) :-
    parent(tom, bob).

test(grandparent, [nondet]) :-
    grandparent(tom, ann).

test(sibling) :-
    sibling(ann, pat).

test(ancestor, [nondet]) :-
    ancestor(tom, ann).

test(find_all_children, set(C == [bob, liz])) :-
    parent(tom, C).

:- end_tests(family).
