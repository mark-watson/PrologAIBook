%% frequentist_demo.pl — Frequentist medical-screening example
%%
%% Re-examines the same screening-test scenario from a purely
%% frequentist standpoint: chi-squared test, Wilson CI for PPV,
%% z-test, and side-by-side comparison with the Bayesian posterior.

:- module(frequentist_demo, [
    run_frequentist_demo/0
]).

:- use_module(bayes).
:- use_module(frequentist).
:- use_module(library(random)).

prevalence(0.001).
sensitivity(0.99).
false_positive_rate(0.05).

likelihood(disease, P) :- sensitivity(P).
likelihood(healthy, P) :- false_positive_rate(P).

%% simulate_screening(+N, -TP, -FP, -TN, -FN)
simulate_screening(N, TP, FP, TN, FN) :-
    prevalence(Prev), sensitivity(Sens), false_positive_rate(FPR),
    simulate_loop(N, Prev, Sens, FPR, 0, 0, 0, 0, TP, FP, TN, FN).

simulate_loop(0, _, _, _, TP, FP, TN, FN, TP, FP, TN, FN) :- !.
simulate_loop(N, Prev, Sens, FPR, TP0, FP0, TN0, FN0, TP, FP, TN, FN) :-
    N > 0,
    random(R1),
    (   R1 < Prev
    ->  Sick = true
    ;   Sick = false
    ),
    random(R2),
    (   Sick = true
    ->  (R2 < Sens -> Pos = true ; Pos = false)
    ;   (R2 < FPR  -> Pos = true ; Pos = false)
    ),
    (   Sick = true,  Pos = true  -> TP1 is TP0+1, FP1=FP0, TN1=TN0,
        FN1=FN0
    ;   Sick = true,  Pos = false -> FN1 is FN0+1, TP1=TP0, FP1=FP0,
        TN1=TN0
    ;   Sick = false, Pos = true  -> FP1 is FP0+1, TP1=TP0, TN1=TN0,
        FN1=FN0
    ;   /* healthy, negative */      TN1 is TN0+1, TP1=TP0, FP1=FP0,
        FN1=FN0
    ),
    N1 is N - 1,
    simulate_loop(N1, Prev, Sens, FPR, TP1, FP1, TN1, FN1, TP, FP, TN,
        FN).

format_pval(PVal) :-
    (   PVal < 1.0e-15
    ->  write('< 1e-15')
    ;   format('~e', [PVal])
    ).

run_frequentist_demo :-





                        format('~n================================================================~n'),
    format('  FREQUENTIST ANALYSIS: Medical Screening Test~n'),





                        format('================================================================~n'),
    %% 1. Simulate
    simulate_screening(100000, TP, FP, TN, FN),
    Total is TP + FP + TN + FN,
    format('~n--- 1. Simulated Clinical Trial (N = ~w) ---~n', [Total]),
    format('  True  Positives (TP): ~w~n', [TP]),
    format('  False Positives (FP): ~w~n', [FP]),
    format('  True  Negatives (TN): ~w~n', [TN]),
    format('  False Negatives (FN): ~w~n', [FN]),
    %% 2. Chi-squared
    format('~n--- 2. Chi-Squared Test of Independence ---~n'),
    R1 is TP + FP, R2 is FN + TN,
    C1 is TP + FN, C2 is FP + TN,
    NF is float(Total),
    ETP is R1*C1/NF, EFP is R1*C2/NF,
    EFN is R2*C1/NF, ETN is R2*C2/NF,
    chi_squared_test([TP,FP,FN,TN], [ETP,EFP,EFN,ETN], _, result(Chi2,
        DF,PVal)),
    format('  chi-squared = ~2f   df = ~w   p-value ', [Chi2, DF]),
    format_pval(PVal), nl,
    format('~n  The association exists but says nothing about~n'),
    format('  how strong it is for one patient.~n'),
    %% 3. PPV
    Positives is TP + FP,
    (Positives =:= 0 -> PPV = 0.0 ; PPV is float(TP) / Positives),
    format('~n--- 3. Positive Predictive Value (PPV) ---~n'),
    PPVPct is PPV * 100.0,
    format('  PPV = ~w / ~w = ~4f  (~2f %)~n', [TP, Positives, PPV,
        PPVPct]),
    confidence_interval_proportion(TP, Positives, 0.95, result(Lo, Hi)),
    LoPct is Lo*100, HiPct is Hi*100,
    format('  95% Wilson CI for PPV: [~4f, ~4f]  (~2f% - ~2f%)~n',
           [Lo, Hi, LoPct, HiPct]),
    %% 4. Z-test
    format('~n--- 4. Z-Test: Positive Rate vs. Prevalence ---~n'),
    prevalence(Prev),
    z_test_proportion(Positives, Total, Prev, result(ZVal, ZPVal)),
    ObsRate is float(Positives) / Total * 100.0,
    PrevPct is Prev * 100.0,
    format('  Observed positive rate: ~4f%~n', [ObsRate]),
    format('  Hypothesised rate (prevalence): ~4f%~n', [PrevPct]),
    format('  z = ~4f   p-value ', [ZVal]),
    format_pval(ZPVal), nl,
    %% 5. Side-by-side
    format('~n--- 5. Bayesian vs. Frequentist Side-by-Side ---~n'),
    Healthy is 1.0 - Prev,
    make_bayes_model([disease-Prev, healthy-Healthy], PriorModel),
    update(PriorModel, positive_test, likelihood, PostModel),
    posterior(PostModel, disease, PDisease),
    PDPct is PDisease * 100.0,
    format('  Bayesian posterior P(disease | positive) = ~4f  (~2f%)~n',
           [PDisease, PDPct]),
    format('  Frequentist PPV from simulation          = ~4f  (~2f%)~n',
           [PPV, PPVPct]),





                        format('~n  Both frameworks agree: about 2% probability of illness.~n'),





                        format('================================================================~n'),





                        format('  Key lesson: statistical significance /= practical significance.~n'),





                        format('================================================================~n').
