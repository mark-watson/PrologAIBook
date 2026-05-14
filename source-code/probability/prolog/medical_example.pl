%% medical_example.pl — Bayesian medical-screening worked example
%%
%% A rare disease affects 0.1% of the population.
%% Sensitivity = 99%, false-positive rate = 5%.
%% Question: positive test → probability of disease?
%% Answer: only about 1.9%.

:- module(medical_example, [
    run_medical_example/0,
    run_bayesian_analysis/0,
    run_correlation_analysis/0
]).

:- use_module(bayes).
:- use_module(correlation).
:- use_module(library(random)).
:- use_module(library(apply)).
:- use_module(library(lists)).

prevalence(0.001).
sensitivity(0.99).
false_positive_rate(0.05).

likelihood(disease, P) :- sensitivity(P).
likelihood(healthy, P) :- false_positive_rate(P).

run_bayesian_analysis :-
    prevalence(Prev),
    Healthy is 1.0 - Prev,
    make_bayes_model([disease-Prev, healthy-Healthy], Prior),
    update(Prior, positive_test, likelihood, Updated),
    format('~n=== Bayesian Analysis: Medical Screening Test ===~n'),
    format('Prior probabilities:~n'),
    print_model(Prior),
    format('~nAfter a POSITIVE test result:~n'),
    print_model(Updated),
    maximum_a_posteriori(Updated, BestH-_),
    format('~nMAP hypothesis: ~w~n', [BestH]),
    format('~nKey insight: despite 99% sensitivity, a positive test~n'),
    format('only yields about 1.9% probability of disease because the~n'),
    format('disease is so rare (0.1% prevalence).~n').

print_model([]).
print_model([H-P|Rest]) :-
    Pct is P * 100.0,
    format('  P(~w) = ~4f  (~2f %)~n', [H, P, Pct]),
    print_model(Rest).

generate_synthetic_population(N, Tests, Diagnoses) :-
    prevalence(Prev), sensitivity(Sens), false_positive_rate(FPR),
    length(Tests, N), length(Diagnoses, N),
    maplist(simulate_individual(Prev, Sens, FPR), Tests, Diagnoses).

simulate_individual(Prev, Sens, FPR, Test, Diag) :-
    random(R1),
    (   R1 < Prev
    ->  Diag = 1.0, random(R2), (R2 < Sens -> Test = 1.0 ; Test = 0.0)
    ;   Diag = 0.0, random(R3), (R3 < FPR  -> Test = 1.0 ; Test = 0.0)
    ).

run_correlation_analysis :-
    N = 100000,
    generate_synthetic_population(N, Tests, Diagnoses),
    pearson_r(Tests, Diagnoses, R),
    format('~n=== Correlation Analysis (N = ~d) ===~n', [N]),
    format('Pearson r(test-result, disease) = ~4f~n', [R]),
    format('~nCorrelation is real but modest — individual prediction~n'),
    format('requires Bayesian reasoning with the base rate.~n').

run_medical_example :-
    run_bayesian_analysis,
    run_correlation_analysis,
    format('~n=== Done. ===~n').
