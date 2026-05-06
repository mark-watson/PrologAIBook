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

%% Example knowledge base (simple)
:- assert(prob_fact(cloudy, 0.5)).
:- assert(prob_fact(windy, 0.3)).
:- assert(prob_rule([cloudy], rain, 0.8)).
:- assert(prob_rule([rain, windy], storm, 0.7)).

%% Complex weather knowledge base
%% 5 base facts, 7 rules, 4 levels of reasoning depth
%% Chain: low_pressure -> unstable_air -> thick_clouds -> severe_storm -> tornado_risk
%%        cold_front + warm_front -> frontal_zone -> storm_system -> severe_storm -> flash_flood_risk
%% Probabilities:
%%   P(unstable_air)      = 0.5*0.8                       = 0.4
%%   P(thick_clouds)      = 0.5*0.4*0.5                   = 0.1
%%   P(frontal_zone)      = 0.5*0.5*0.6                   = 0.15
%%   P(storm_system)      = 0.15*0.5*0.8                  = 0.06
%%   P(severe_storm)      = 0.1*0.06*0.5                  = 0.003
%%   P(tornado_risk)      = 0.003*0.6                     = 0.0018
%%   P(flash_flood_risk)  = 0.003*0.8                     = 0.0024
:- assert(prob_fact(low_pressure, 0.5)).
:- assert(prob_fact(high_humidity, 0.5)).
:- assert(prob_fact(cold_front, 0.5)).
:- assert(prob_fact(warm_front, 0.5)).
:- assert(prob_fact(jet_stream_dip, 0.5)).
:- assert(prob_rule([low_pressure], unstable_air, 0.8)).
:- assert(prob_rule([high_humidity, unstable_air], thick_clouds, 0.5)).
:- assert(prob_rule([cold_front, warm_front], frontal_zone, 0.6)).
:- assert(prob_rule([frontal_zone, jet_stream_dip], storm_system, 0.8)).
:- assert(prob_rule([thick_clouds, storm_system], severe_storm, 0.5)).
:- assert(prob_rule([severe_storm], tornado_risk, 0.6)).
:- assert(prob_rule([severe_storm], flash_flood_risk, 0.8)).
