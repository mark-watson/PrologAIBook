%% prob_facts.pl - Probabilistic reasoning with certainty factors
%% A lightweight implementation without external pack dependencies
:- module(prob_facts, [
    prob_fact/2,
    prob_rule/3,
    prob_query/2
]).

:- dynamic prob_fact/2.  % prob_fact(Fact, Probability)

%% prob_rule(+Conditions, +Conclusion, +CondProb)
%% If all Conditions hold, conclude Conclusion with conditional probability
:- dynamic prob_rule/3.

%% prob_query(+Goal, -Probability)
%% Query the probability of a goal given known facts and rules
prob_query(Goal, Prob) :-
    prob_fact(Goal, Prob), !.
prob_query(Goal, Prob) :-
    prob_rule(Conditions, Goal, CondProb),
    maplist(prob_query, Conditions, CondProbs),
    foldl(mul, CondProbs, 1.0, JointProb),
    Prob is JointProb * CondProb.

mul(X, Acc, Result) :- Result is Acc * X.

%% Example knowledge base
:- assert(prob_fact(cloudy, 0.5)).
:- assert(prob_fact(windy, 0.3)).
:- assert(prob_rule([cloudy], rain, 0.8)).
:- assert(prob_rule([rain, windy], storm, 0.7)).
