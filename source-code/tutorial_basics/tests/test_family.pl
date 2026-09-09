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

test(ancestor_within_direct, [nondet]) :-
    ancestor_within(tom, bob, 1).

test(ancestor_within_two_steps, [nondet]) :-
    ancestor_within(tom, ann, 2).

test(ancestor_within_too_shallow, [fail]) :-
    ancestor_within(tom, ann, 1).

:- end_tests(family).
