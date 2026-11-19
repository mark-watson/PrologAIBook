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
%% Each #pred template turns a goal into an English phrase. @(Var)
%% inserts the value of a variable. Keep each template on one line:
%% a line break inside the quotes would show up in the explanation.
:- style_check(-singleton).
#pred eligible_for_reimbursement(Person) ::
    '@(Person) is eligible for travel reimbursement'.
#pred employee(Person) :: '@(Person) is a registered employee'.
#pred business_travel(Person) ::
    '@(Person)\'s trip was for business purposes'.
#pred personal_travel(Person) ::
    '@(Person)\'s trip was for personal reasons'.
#pred travel_limit_exceeded(Person) ::
    '@(Person) has exceeded the travel expense limit of $500'.
#pred expense_amount(Person, Amount) ::
    '@(Person)\'s travel expense amount is $@(Amount)'.
:- style_check(+singleton).

%% run_compliance_check(+Person)
%% Print whether Person is eligible and the s(CASP) justification.
%% For a denial we query the negated goal, so s(CASP) explains why
%% the person is NOT eligible. Each query runs inside \+ \+ so its
%% bindings are undone before the next query starts; leftover
%% bindings from one s(CASP) query can break the next one.
run_compliance_check(Person) :-
    (   \+ \+ show_result(eligible_for_reimbursement(Person),
                          '~w is eligible.', Person)
    ->  true
    ;   \+ \+ show_result(not eligible_for_reimbursement(Person),
                          '~w is NOT eligible.', Person)
    ->  true
    ;   format('No s(CASP) model found for ~w.~n', [Person])
    ).

show_result(Query, Headline, Person) :-
    scasp(Query, [tree(Tree)]),
    !,
    format(Headline, [Person]),
    format('~n~nJustification Tree:~n'),
    with_output_to(string(Text), human_justification_tree(Tree, [])),
    %% scasp 2.0.1 prints an HTML non-breaking space in comparisons.
    atomic_list_concat(Parts, '&(nbsp)', Text),
    atomic_list_concat(Parts, ' ', Clean),
    format('~w~n', [Clean]).
