%% sample_kb.pl - Small knowledge bases for the meta-interpreters
:- module(sample_kb, []).

%% A graph with a cycle, and a LEFT-recursive path/2. Plain Prolog
%% loops forever on path(a, X); mi_bfs/3 does not.
edge(a, b).
edge(b, c).
edge(c, a).
edge(c, d).

path(X, Y) :- path(X, Z), edge(Z, Y).
path(X, Y) :- edge(X, Y).

%% Facts and rules for tracing.
parent(tom, bob).
parent(bob, ann).
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
older(X, Y) :- age(X, A), age(Y, B), A > B.
age(tom, 70).
age(bob, 45).

%% Rules with certainty factors for mi_cf/3.
cf_rule(fever, true, 0.9).
cf_rule(cough, true, 0.6).
cf_rule(rash, true, 0.3).
cf_rule(flu, (fever, cough), 0.8).
cf_rule(measles, (fever, rash), 0.9).
cf_rule(see_doctor, flu, 0.7).
cf_rule(see_doctor, measles, 1.0).
