%% bayes.pl — Bayesian inference core
%%
%% A Bayes model is a normalised list of Hypothesis-Probability pairs.
%% update/4 applies Bayes' Theorem:
%%
%%   P(H | E) = P(E | H) · P(H) / Σ_h P(E | h) · P(h)

:- module(bayes, [
    make_bayes_model/2,
    update/4,
    posterior/3,
    posteriors/2,
    maximum_a_posteriori/2
]).

:- use_module(library(lists)).
:- use_module(library(apply)).

%% make_bayes_model(+PriorPairs, -Model)
%% PriorPairs is a list of Hypothesis-Prior pairs.
%% Priors are automatically normalised so they sum to 1.
make_bayes_model(PriorPairs, Model) :-
    maplist(pair_value, PriorPairs, Priors),
    sumlist(Priors, Total),
    (   Total =:= 0
    ->  throw(error(all_priors_zero,
        'All priors are zero — cannot normalise.'))
    ;   maplist(normalise_pair(Total), PriorPairs, Model)
    ).

pair_value(_-V, V).

normalise_pair(Total, H-P, H-NP) :-
    NP is P / Total.

:- meta_predicate update(+, +, 2, -).

%% update(+Model, +Evidence, :LikelihoodPred, -Updated)
%% LikelihoodPred is a predicate of arity 2: LikelihoodPred(Hypothesis,
%% P)
%% that binds P to P(Evidence | Hypothesis) when called.
%% Evidence is passed for documentation but not used directly.
%% Example: update(Model, positive, my_lik, Updated)
%%   where my_lik(disease, 0.99) and my_lik(healthy, 0.05) are defined.
update(Model, _Evidence, LikelihoodPred, Updated) :-
    maplist(unnormalised_posterior(LikelihoodPred), Model,
        Unnormalised),
    maplist(pair_value, Unnormalised, UnnormProbs),
    sumlist(UnnormProbs, Marginal),
    (   Marginal =:= 0.0
    ->  throw(error(zero_marginal,





                                  'Marginal likelihood is zero — evidence impossible under all hypotheses.'))
    ;   maplist(normalise_pair(Marginal), Unnormalised, Updated)
    ).

unnormalised_posterior(LikelihoodPred, H-Prior, H-UPost) :-
    call(LikelihoodPred, H, Lik),
    UPost is Lik * Prior.

%% posterior(+Model, +Hypothesis, -Probability)
%% Look up the posterior for a single hypothesis.
posterior(Model, Hypothesis, Prob) :-
    member(Hypothesis-Prob, Model), !.
posterior(_, Hypothesis, _) :-
    throw(error(hypothesis_not_found,
          Hypothesis)).

%% posteriors(+Model, -Pairs)
%% Return the full list of Hypothesis-Probability pairs.
posteriors(Model, Model).

%% maximum_a_posteriori(+Model, -Best)
%% Return the Hypothesis-Probability pair with the highest posterior.
maximum_a_posteriori([First|Rest], Best) :-
    foldl(pick_max, Rest, First, Best).

pick_max(H-P, _-BestP, H-P) :- P > BestP, !.
pick_max(_, Best, Best).
