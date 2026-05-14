%% frequentist.pl — Frequentist hypothesis-testing toolkit
%%
%% Provides the core tools of null-hypothesis significance testing:
%% z-tests, chi-squared tests, and confidence intervals.
%%
%% IMPORTANT CAVEAT (repeated deliberately):
%% A small p-value tells you the observed data would be unlikely
%% *if* the null hypothesis were true.  It does NOT tell you the
%% probability that the null hypothesis is false, nor the probability
%% that your alternative hypothesis is true.  Confusing these is the
%% single most common error in applied statistics.

:- module(frequentist, [
    z_score/3,
    z_test_proportion/4,
    chi_squared_test/4,
    confidence_interval_proportion/4,
    phi_approx/2
]).

:- use_module(library(lists)).
:- use_module(library(apply)).

%% ======================================================================
%%  Normal CDF approximation (Abramowitz & Stegun 26.2.17)
%%
%%  Maximum absolute error: 1.5 × 10⁻⁷
%%  Input: z (real number)
%%  Output: Φ(z) = P(Z ≤ z) for Z ~ N(0,1)
%% ======================================================================

phi_approx(Z, CDF) :-
    P  = 0.2316419,
    B1 = 0.319381530,
    B2 = -0.356563782,
    B3 = 1.781477937,
    B4 = -1.821255978,
    B5 = 1.330274429,
    AZ is abs(Z),
    TVal is 1.0 / (1.0 + P * AZ),
    PDF is exp(-0.5 * AZ * AZ) / sqrt(2.0 * pi),
    CDF0 is 1.0 - PDF * (B1*TVal
                         + B2*TVal^2
                         + B3*TVal^3
                         + B4*TVal^4
                         + B5*TVal^5),
    (   Z >= 0.0
    ->  CDF = CDF0
    ;   CDF is 1.0 - CDF0
    ).

%% ======================================================================
%%  Chi-squared CDF approximation (Wilson–Hilferty, 1931)
%%
%%  Transforms chi² to an approximately standard-normal variate:
%%     z ≈ ((χ²/k)^(1/3) − (1 − 2/(9k))) / sqrt(2/(9k))
%%  then uses phi_approx.  Good for df ≥ 3; acceptable for df ≥ 1.
%% ======================================================================

chi_squared_cdf(X, DF, CDF) :-
    (   X =< 0.0
    ->  CDF = 0.0
    ;   K is float(DF),
        Term is 2.0 / (9.0 * K),
        ZVal is ((X / K) ** (1.0/3.0) - (1.0 - Term)) / sqrt(Term),
        phi_approx(ZVal, CDF)
    ).

%% ======================================================================
%%  Z-score
%% ======================================================================

%% z_score(+Observed, +Expected, +StdDev, -Z)
z_score(Observed, Expected, StdDev) :-
    StdDev > 0,
    _ is (float(Observed) - float(Expected)) / float(StdDev).

%% z_score(+Observed, +Expected, +StdDev, -Z)
z_score(Observed, Expected, StdDev, Z) :-
    StdDev > 0,
    Z is (float(Observed) - float(Expected)) / float(StdDev).

%% ======================================================================
%%  One-sample z-test for a proportion
%% ======================================================================

%% z_test_proportion(+Successes, +N, +HypothesisedP, -result(Z, PValue))
%% Tests H₀: p = HypothesisedP against H₁: p ≠ HypothesisedP (two-tailed).
z_test_proportion(Successes, N, HypP, result(Z, PVal)) :-
    P0  is float(HypP),
    NF  is float(N),
    PHat is float(Successes) / NF,
    SE  is sqrt(P0 * (1.0 - P0) / NF),
    Z   is (PHat - P0) / SE,
    phi_approx(abs(Z), PhiAbs),
    PVal0 is 2.0 * (1.0 - PhiAbs),
    PVal is min(PVal0, 1.0).

%% ======================================================================
%%  Pearson's chi-squared test (goodness-of-fit)
%% ======================================================================

%% chi_squared_test(+Observed, +Expected, -ChiSq, -result(ChiSq, DF, PValue))
%% Observed and Expected are equal-length lists of non-negative counts.
%% H₀: observed counts follow the expected distribution.
chi_squared_test(Observed, Expected, _, result(ChiSq, DF, PVal)) :-
    length(Observed, Len),
    length(Expected, Len),   % assert same length
    maplist(chi_sq_term, Observed, Expected, Terms),
    sumlist(Terms, ChiSq),
    DF is Len - 1,
    chi_squared_cdf(ChiSq, DF, CCDF),
    PVal is max(1.0 - CCDF, 0.0).

chi_sq_term(O, E, T) :-
    OF is float(O),
    EF is float(E),
    (   EF =:= 0.0
    ->  T = 0.0
    ;   T is (OF - EF)^2 / EF
    ).

%% ======================================================================
%%  Wilson score confidence interval for a proportion
%% ======================================================================

%% z_critical(+Confidence, -ZCrit)
%% Return the z* critical value for a two-sided confidence level.
z_critical(Confidence, ZCrit) :-
    (   abs(Confidence - 0.90) < 1.0e-6
    ->  ZCrit = 1.6449
    ;   abs(Confidence - 0.95) < 1.0e-6
    ->  ZCrit = 1.9600
    ;   abs(Confidence - 0.99) < 1.0e-6
    ->  ZCrit = 2.5758
    ;   %% Fallback: bisection to solve Φ(z) = (1+confidence)/2
        Target is (1.0 + float(Confidence)) / 2.0,
        bisect_z(0.0, 5.0, Target, 60, ZCrit)
    ).

bisect_z(Lo, Hi, _Target, 0, Z) :- Z is (Lo + Hi) / 2.0.
bisect_z(Lo, Hi, Target, Steps, Z) :-
    Steps > 0,
    Mid is (Lo + Hi) / 2.0,
    phi_approx(Mid, Phi),
    Steps1 is Steps - 1,
    (   Phi < Target
    ->  bisect_z(Mid, Hi, Target, Steps1, Z)
    ;   bisect_z(Lo, Mid, Target, Steps1, Z)
    ).

%% confidence_interval_proportion(+Successes, +N, +Confidence, -result(Lower, Upper))
%% Wilson score confidence interval for a binomial proportion.
%% More accurate than the Wald (normal-approximation) interval,
%% especially for small samples or extreme proportions.
confidence_interval_proportion(Successes, N, Confidence, result(Lower, Upper)) :-
    NF is float(N),
    P  is float(Successes) / NF,
    z_critical(Confidence, ZC),
    Z2 is ZC * ZC,
    Denom is 1.0 + Z2 / NF,
    Centre is (P + Z2 / (2.0 * NF)) / Denom,
    Margin is (ZC * sqrt(P * (1.0 - P) / NF + Z2 / (4.0 * NF * NF))) / Denom,
    Lower is max(0.0, Centre - Margin),
    Upper is min(1.0, Centre + Margin).
