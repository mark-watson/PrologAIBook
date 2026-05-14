:- module(test_probability, []).
:- use_module(library(plunit)).
:- use_module('../prolog/bayes').
:- use_module('../prolog/correlation').
:- use_module('../prolog/frequentist').

med_lik(disease, 0.99).
med_lik(healthy, 0.05).

:- begin_tests(bayes).

test(make_model_normalises) :-
    make_bayes_model([a-1, b-3], Model),
    member(a-PA, Model),
    member(b-PB, Model),
    abs(PA - 0.25) < 0.001,
    abs(PB - 0.75) < 0.001.

test(posterior_lookup) :-
    make_bayes_model([x-0.5, y-0.5], Model),
    posterior(Model, x, P),
    abs(P - 0.5) < 0.001.

test(maximum_a_posteriori) :-
    make_bayes_model([a-0.2, b-0.8], Model),
    maximum_a_posteriori(Model, Best-_),
    Best == b.

test(medical_posterior) :-
    Prev = 0.001,
    Healthy is 1.0 - Prev,
    make_bayes_model([disease-Prev, healthy-Healthy], Prior),
    update(Prior, positive, test_probability:med_lik, Updated),
    posterior(Updated, disease, PD),
    %% Should be approximately 0.0194 (1.94%)
    abs(PD - 0.0194) < 0.005.

:- end_tests(bayes).

:- begin_tests(correlation).

test(pearson_perfect_positive) :-
    pearson_r([1.0, 2.0, 3.0, 4.0, 5.0],
              [2.0, 4.0, 6.0, 8.0, 10.0], R),
    abs(R - 1.0) < 0.001.

test(pearson_perfect_negative) :-
    pearson_r([1.0, 2.0, 3.0, 4.0, 5.0],
              [10.0, 8.0, 6.0, 4.0, 2.0], R),
    abs(R - (-1.0)) < 0.001.

test(pearson_zero_constant) :-
    pearson_r([1.0, 2.0, 3.0], [5.0, 5.0, 5.0], R),
    R =:= 0.0.

test(spearman_monotonic) :-
    spearman_rho([1.0, 2.0, 3.0, 4.0],
                 [1.0, 4.0, 9.0, 16.0], Rho),
    abs(Rho - 1.0) < 0.001.

test(list_mean) :-
    list_mean([2.0, 4.0, 6.0], M),
    abs(M - 4.0) < 0.001.

test(list_std_dev) :-
    list_std_dev([2.0, 4.0, 6.0], SD),
    %% population std dev of [2,4,6] = sqrt(8/3) ≈ 1.6330
    abs(SD - 1.6330) < 0.01.

:- end_tests(correlation).

:- begin_tests(frequentist).

test(phi_approx_zero) :-
    phi_approx(0.0, CDF),
    abs(CDF - 0.5) < 0.001.

test(phi_approx_large_positive) :-
    phi_approx(3.0, CDF),
    CDF > 0.998.

test(phi_approx_negative) :-
    phi_approx(-1.96, CDF),
    abs(CDF - 0.025) < 0.002.

test(z_test_proportion_large) :-
    %% 550 successes out of 1000, H0: p=0.5
    z_test_proportion(550, 1000, 0.5, result(Z, PVal)),
    abs(Z - 3.162) < 0.1,
    PVal < 0.01.

test(wilson_ci_covers_half) :-
    %% 500/1000 should give CI containing 0.5
    confidence_interval_proportion(500, 1000, 0.95, result(Lo, Hi)),
    Lo < 0.5,
    Hi > 0.5.

:- end_tests(frequentist).
