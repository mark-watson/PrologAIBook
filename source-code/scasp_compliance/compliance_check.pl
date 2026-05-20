:- module(compliance_check, [
    eligible_for_reimbursement/1,
    run_compliance_check/1
]).

:- use_module(library(scasp)).
:- use_module(library(scasp/human)).

:- discontiguous employee/1.
:- discontiguous business_travel/1.
:- discontiguous expense_amount/2.

%% Policy Rules
eligible_for_reimbursement(Person) :-
    employee(Person),
    business_travel(Person),
    not personal_travel(Person),
    not travel_limit_exceeded(Person).

travel_limit_exceeded(Person) :-
    expense_amount(Person, Amount),
    Amount > 500.

%% Facts
employee(alice).
business_travel(alice).
expense_amount(alice, 350).

employee(bob).
business_travel(bob).
expense_amount(bob, 650).

employee(charlie).
business_travel(charlie).
personal_travel(charlie).
expense_amount(charlie, 150).

%% s(CASP) Explanations/Translations
#pred eligible_for_reimbursement(Person) :: '@(Person) is eligible for travel reimbursement'.
#pred employee(Person) :: '@(Person) is a registered employee'.
#pred business_travel(Person) :: '@(Person)\'s trip was for business purposes'.
#pred personal_travel(Person) :: '@(Person)\'s trip was for personal reasons'.
#pred travel_limit_exceeded(Person) :: '@(Person) has exceeded the travel expense limit of $500'.
#pred expense_amount(Person, Amount) :: '@(Person)\'s travel expense amount is $ @(Amount)'.

%% Helper to run and output the explanation
run_compliance_check(Person) :-
    (   scasp(eligible_for_reimbursement(Person), [tree(Tree)])
    ->  format('~w is eligible.~n~n', [Person]),
        writeln('Justification Tree:'),
        human_justification_tree(Tree, [])
    ;   format('~w is NOT eligible or compliance check failed.~n', [Person])
    ).
