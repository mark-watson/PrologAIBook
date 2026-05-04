%% family.pl - Facts, rules, and queries about family relationships
%% Demonstrates: facts, rules, queries, unification, backtracking

:- module(family, [
    parent/2,
    grandparent/2,
    sibling/2,
    ancestor/2
]).

%% Facts: parent(Parent, Child)
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).

%% Rules
grandparent(X, Z) :-
    parent(X, Y),
    parent(Y, Z).

sibling(X, Y) :-
    parent(Z, X),
    parent(Z, Y),
    X \= Y.

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :-
    parent(X, Z),
    ancestor(Z, Y).
