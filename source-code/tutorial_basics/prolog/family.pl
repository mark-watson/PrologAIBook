%% family.pl - Facts, rules, and queries about family relationships
%% Demonstrates: facts, rules, queries, unification, backtracking

:- module(family, [
    parent/2,
    grandparent/2,
    sibling/2,
    ancestor/2,
    ancestor_within/3
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

%% ancestor(+X, -Y) / ancestor(X, Y)
%%
%% WARNING: this naive transitive closure is safe only for acyclic
%% `parent/2` data. If the data contains a cycle (e.g. by mistake a
%% person is their own ancestor) or if the rules were written in the
%% left-recursive form `ancestor(X,Z), parent(Z,Y)`, queries would not
%% terminate. Use ancestor_within/3 for a depth-bounded, always
%% terminating variant.
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :-
    parent(X, Z),
    ancestor(Z, Y).

%% ancestor_within(+X, -Y, +MaxDepth)
%% Depth-bounded ancestor search: yields each ancestor of X found
%% within MaxDepth parent/2 steps. Terminates even for cyclic data.
ancestor_within(X, Y, MaxDepth) :-
    MaxDepth > 0,
    parent(X, Z),
    (   Y = Z
    ;   MaxDepth1 is MaxDepth - 1,
        ancestor_within(Z, Y, MaxDepth1)
    ).
