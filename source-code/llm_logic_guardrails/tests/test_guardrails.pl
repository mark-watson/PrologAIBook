%% test_guardrails.pl — Offline plunit tests for the policy rules.
%%
%% Each test builds a dict directly (no JSON parsing, no network) and
%% checks one policy rule.  Also exercises the atom/string robustness
%% of the risk-tolerance comparison and the missing-key policy error.
:- module(test_guardrails, []).

:- use_module(library(plunit)).
:- use_module('../prolog/guardrails').

:- begin_tests(guardrails).

% --- Rule 1: allocations must sum to 100% ---

test(rule1_sum_not_100,
     [true(Errors == ["Total allocation must sum to exactly 100%"])]) :-
    Dict = _{client_age: 40, risk_tolerance: "medium",
             allocations: _{stocks: 30, bonds: 30, crypto: 0, cash: 30}},
    validate_portfolio_dict(Dict, Errors).

test(rule1_sum_100_ok, [true(Errors == [])]) :-
    Dict = _{client_age: 40, risk_tolerance: "medium",
             allocations: _{stocks: 30, bonds: 40, crypto: 0, cash: 30}},
    validate_portfolio_dict(Dict, Errors).

% --- Rule 2: seniors limited to 30% high-risk assets ---

test(rule2_senior_high_risk, [true(sub_string(Err, _, _, _, "high-risk"))]) :-
    Dict = _{client_age: 70, risk_tolerance: "medium",
             allocations: _{stocks: 20, bonds: 55, crypto: 15, cash: 10}},
    validate_portfolio_dict(Dict, Errors),
    member(Err, Errors).

test(rule2_young_high_risk_ok, [true(Errors == [])]) :-
    Dict = _{client_age: 30, risk_tolerance: "medium",
             allocations: _{stocks: 30, bonds: 40, crypto: 20, cash: 10}},
    validate_portfolio_dict(Dict, Errors).

% --- Rule 3: low risk tolerance forbids crypto ---

test(rule3_low_risk_crypto, [true(Errors ==
    ["Low risk tolerance portfolio cannot contain speculative crypto assets"])]) :-
    Dict = _{client_age: 40, risk_tolerance: "low",
             allocations: _{stocks: 10, bonds: 60, crypto: 5, cash: 25}},
    validate_portfolio_dict(Dict, Errors).

% Same rule must fire when risk_tolerance arrives as an atom (the
% default representation produced by json_read_dict/2).
test(rule3_low_risk_crypto_atom_value, [true(Errors ==
    ["Low risk tolerance portfolio cannot contain speculative crypto assets"])]) :-
    Dict = _{client_age: 40, risk_tolerance: low,
             allocations: _{stocks: 10, bonds: 60, crypto: 5, cash: 25}},
    validate_portfolio_dict(Dict, Errors).

test(rule3_medium_risk_crypto_ok, [true(Errors == [])]) :-
    Dict = _{client_age: 40, risk_tolerance: "medium",
             allocations: _{stocks: 20, bonds: 50, crypto: 5, cash: 25}},
    validate_portfolio_dict(Dict, Errors).

% --- Rule 4: low risk tolerance needs >= 50% conservative assets ---

test(rule4_low_risk_conservative, [true(sub_string(Err, _, _, _, "conservative"))]) :-
    Dict = _{client_age: 40, risk_tolerance: "low",
             allocations: _{stocks: 60, bonds: 30, crypto: 0, cash: 10}},
    validate_portfolio_dict(Dict, Errors),
    member(Err, Errors).

test(rule4_low_risk_conservative_ok, [true(Errors == [])]) :-
    Dict = _{client_age: 40, risk_tolerance: "low",
             allocations: _{stocks: 20, bonds: 50, crypto: 0, cash: 30}},
    validate_portfolio_dict(Dict, Errors).

% --- Rule 5: no negative allocations ---

test(rule5_negative_allocation, [true(Errors ==
    ["Asset allocations cannot be negative"])]) :-
    Dict = _{client_age: 40, risk_tolerance: "medium",
             allocations: _{stocks: 110, bonds: 0, crypto: -10, cash: 0}},
    validate_portfolio_dict(Dict, Errors).

test(rule5_all_non_negative_ok, [true(Errors == [])]) :-
    Dict = _{client_age: 40, risk_tolerance: "medium",
             allocations: _{stocks: 25, bonds: 25, crypto: 25, cash: 25}},
    validate_portfolio_dict(Dict, Errors).

% --- Missing keys and malformed JSON produce policy errors ---

test(missing_key_policy_error, [true(sub_string(Err, _, _, _, "Missing required keys"))]) :-
    atom_json_dict('{"risk_tolerance": "low"}', Dict, []),
    validate_portfolio_dict(Dict, [Err|_]).

test(malformed_json_policy_error, [true(sub_string(Err, _, _, _, "Invalid JSON input"))]) :-
    validate_portfolio_json('{not json', [Err|_]).

% Helper: run the policy rules on an already-parsed dict (the tests
% bypass JSON parsing; JSON entry-point behaviour is covered above).
validate_portfolio_dict(Dict, Errors) :-
    guardrails:missing_required_keys(Dict, Missing),
    (   Missing \= []
    ->  atomic_list_concat(Missing, ', ', MissingStr),
        format(string(ErrStr),
            "Missing required keys in recommendation: ~w", [MissingStr]),
        Errors = [ErrStr]
    ;   findall(E, guardrails:check_policy(Dict, E), Errors)
    ).

:- end_tests(guardrails).
