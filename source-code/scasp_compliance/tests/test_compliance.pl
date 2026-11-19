:- module(test_compliance, []).
:- use_module(library(plunit)).
:- use_module(library(scasp)).
:- use_module('../compliance_check').

:- begin_tests(compliance).

test(alice_eligible) :-
    \+ \+ scasp(compliance_check:eligible_for_reimbursement(alice), []).

test(bob_over_limit, [fail]) :-
    \+ \+ scasp(compliance_check:eligible_for_reimbursement(bob), []).

test(charlie_personal_travel, [fail]) :-
    \+ \+ scasp(compliance_check:eligible_for_reimbursement(charlie), []).

test(eligible_set) :-
    findall(P,
            ( member(P, [alice, bob, charlie]),
              \+ \+ scasp(compliance_check:eligible_for_reimbursement(P),
                          []) ),
            Ps),
    assertion(Ps == [alice]).

test(denial_explained) :-
    with_output_to(string(S), run_compliance_check(bob)),
    assertion(sub_string(S, _, _, _, "bob is NOT eligible.")),
    assertion(sub_string(S, _, _, _, "650 is greater than 500")).

test(no_html_entities) :-
    with_output_to(string(S), run_compliance_check(alice)),
    assertion(\+ sub_string(S, _, _, _, "&(nbsp)")).

:- end_tests(compliance).
