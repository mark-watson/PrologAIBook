%% defaults.pl - Default reasoning with negation as failure
:- module(defaults, [
    flies/1,
    bird/1,
    learn/1,
    forget/1
]).

%% penguin/1 and ostrich/1 are dynamic so that a query such as
%% flies(tweety) fails cleanly when no such facts exist, and so
%% that learn/1 can add them later.
:- dynamic penguin/1, ostrich/1, bird/1.

%% Birds fly by default, unless we can prove they are abnormal.
flies(X) :-
    bird(X),
    \+ abnormal(X).

abnormal(X) :- penguin(X).
abnormal(X) :- ostrich(X).

bird(tweety).
bird(pingu).
penguin(pingu).

%% learn(+Fact) and forget(+Fact) change what we know.
learn(Fact) :- assertz(Fact).
forget(Fact) :- retract(Fact).
