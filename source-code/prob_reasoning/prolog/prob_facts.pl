%% prob_facts.pl - Probabilistic reasoning over annotated facts/rules
%%
%% NOTE: the probability arithmetic below is noisy-AND style
%% multiplication along the inference chain; it is NOT MYCIN-style
%% certainty-factor combination.
%%
%% Product chains are computed in log space (a foldl of the log of each
%% factor, then exp/1 of the sum) so that deep chains do not underflow
%% to 0.0 in floating point.
%%
%% prob_query/3 carries a visited-goal list so that cyclic rule bases
%% terminate: a goal already on the current reasoning branch fails
%% instead of looping forever.
%%
%% The dynamic facts and rules are empty at module load; call
%% load_example_kb/0 (see load.pl) to populate the weather example.

:- module(prob_facts, [
    prob_fact/2,
    prob_rule/3,
    prob_query/2,
    load_example_kb/0
]).

:- dynamic prob_fact/2.  % prob_fact(Fact, Probability)

%% prob_rule(+Conditions, +Conclusion, +CondProb)
%% If all Conditions hold, conclude Conclusion with conditional
%% probability
:- dynamic prob_rule/3.

%% prob_query(+Goal, -Probability)
%% Query the probability of a goal given known facts and rules
prob_query(Goal, Prob) :-
    prob_query(Goal, Prob, []).

%% prob_query(+Goal, -Probability, +Visited) - Visited guards cycles
prob_query(Goal, _, Visited) :-
    member(Goal, Visited),
    !,
    fail.
prob_query(Goal, Prob, _) :-
    prob_fact(Goal, Prob), !.
prob_query(Goal, Prob, Visited) :-
    prob_rule(Conditions, Goal, CondProb),
    maplist(prob_query_([Goal|Visited]), Conditions, CondProbs),
    foldl(sum_log, CondProbs, 0.0, LogJoint),
    Prob is exp(LogJoint) * CondProb.

%% Bridge for maplist so Visited is threaded into recursive calls
prob_query_(Visited, Goal, Prob) :-
    prob_query(Goal, Prob, Visited).

%% sum_log(+P, +Acc, -Result)
%% Accumulate log probabilities; P =:= 0.0 contributes -inf.
sum_log(P, Acc, Result) :-
    (   P =:= 0.0
    ->  Result = -inf
    ;   Result is Acc + log(P)
    ).

%% load_example_kb - Assert the weather example knowledge base.
%% Idempotent: retracts any existing KB first, so it is safe to call
%% repeatedly (e.g. on reload).
load_example_kb :-
    retractall(prob_fact(_, _)),
    retractall(prob_rule(_, _, _)),
    assertz(prob_fact(cloudy, 0.5)),
    assertz(prob_fact(windy, 0.3)),
    assertz(prob_rule([cloudy], rain, 0.8)),
    assertz(prob_rule([rain, windy], storm, 0.7)),
    %% Complex weather knowledge base
    %% 5 base facts, 7 rules, 4 levels of reasoning depth
    %% Chain: low_pressure -> unstable_air -> thick_clouds ->
    %% severe_storm -> tornado_risk
    %%        cold_front + warm_front -> frontal_zone -> storm_system
    %%        -> severe_storm -> flash_flood_risk
    %% Probabilities:
    %%   P(unstable_air)      = 0.5*0.8                   = 0.4
    %%   P(thick_clouds)      = 0.5*0.4*0.5               = 0.1
    %%   P(frontal_zone)      = 0.5*0.5*0.6               = 0.15
    %%   P(storm_system)      = 0.15*0.5*0.8              = 0.06
    %%   P(severe_storm)      = 0.1*0.06*0.5              = 0.003
    %%   P(tornado_risk)      = 0.003*0.6                 = 0.0018
    %%   P(flash_flood_risk)  = 0.003*0.8                 = 0.0024
    assertz(prob_fact(low_pressure, 0.5)),
    assertz(prob_fact(high_humidity, 0.5)),
    assertz(prob_fact(cold_front, 0.5)),
    assertz(prob_fact(warm_front, 0.5)),
    assertz(prob_fact(jet_stream_dip, 0.5)),
    assertz(prob_rule([low_pressure], unstable_air, 0.8)),
    assertz(prob_rule([high_humidity, unstable_air], thick_clouds, 0.5)),
    assertz(prob_rule([cold_front, warm_front], frontal_zone, 0.6)),
    assertz(prob_rule([frontal_zone, jet_stream_dip], storm_system, 0.8)),
    assertz(prob_rule([thick_clouds, storm_system], severe_storm, 0.5)),
    assertz(prob_rule([severe_storm], tornado_risk, 0.6)),
    assertz(prob_rule([severe_storm], flash_flood_risk, 0.8)).
