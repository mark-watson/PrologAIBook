# Explainable AI and Computational Law with s(CASP)

As artificial intelligence systems are increasingly deployed to automate administrative and legal decisions, the field of **Computational Law** (often called "Rules as Code") has gained significant traction. This field aims to draft legislation, tax codes, corporate policies, and safety standards directly as computer-executable logic. 

However, executing rules is only half the battle. In regulated domains, we cannot rely on black-box predictions. If an AI system denies a citizen a government benefit, rejects a travel expense reimbursement, or flags a financial transaction for compliance auditing, the system **must** be able to explain *why* it made that decision. 

Traditional machine learning algorithms cannot provide these explanations. Standard Prolog engines can produce proof trees, but they struggle with negation-as-failure under complex constraints.

**s(CASP)** (Goal-Directed Answer Set Programming) solves this. It compiles logic rules and evaluates queries by generating a mathematical **justification tree**. Instead of returning a simple `true` or `false`, s(CASP) explains the exact chain of rules, facts, and lack of contradictory evidence that led to its conclusion.


{width: "80%"}
![Architecture diagram for the s(CASP) Compliance example](FIG_scasp_compliance.jpg)


## What is s(CASP)?

`s(CASP)` is a first-order logic programming system that combines features of constraint logic programming and Answer Set Programming:
- **Goal-Directed**: Unlike traditional ASP solvers that must compute all possible stable models (which is computationally expensive for large systems), s(CASP) evaluates specific queries on demand, similar to standard Prolog.
- **Justification Trees**: It constructs a step-by-step trace of which rules were satisfied and which negative constraints were successfully avoided.
- **Predicates for Natural Language**: It allows developers to define `#pred` templates that translate raw logic terms into human-readable sentences, generating explanations directly from the justification tree.

---

## Implementing Compliance Rules

We will model a corporate travel expense reimbursement policy. Under this policy, a person is eligible for reimbursement if:
1. They are an employee.
2. The travel was for business purposes.
3. The travel was *not* for personal reasons.
4. They did *not* exceed their expense limit of $500.

Here is the implementation in **source-code/scasp_compliance/compliance_check.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
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
#pred eligible_for_reimbursement(Person) ::
    '@(Person) is eligible for travel reimbursement'.
#pred employee(Person) :: '@(Person) is a registered employee'.
#pred business_travel(Person) :: '@(Person)\'s trip was for business
    purposes'.
#pred personal_travel(Person) :: '@(Person)\'s trip was for personal
    reasons'.
#pred travel_limit_exceeded(Person) ::
    '@(Person) has exceeded the travel expense limit of $500'.
#pred expense_amount(Person, Amount) :: '@(Person)\'s travel expense
    amount is $ @(Amount)'.

%% Helper to run and output the explanation
run_compliance_check(Person) :-
    (   scasp(eligible_for_reimbursement(Person), [tree(Tree)])
    ->  format('~w is eligible.~n~n', [Person]),
        writeln('Justification Tree:'),
        human_justification_tree(Tree, [])
    ;   format('~w is NOT eligible or compliance check failed.~n',
        [Person])
    ).
~~~~~~~~

Note how the `#pred` declarations use the `@(Variable)` syntax to map variables to their text representations. The `not` prefix represents default negation, meaning the rule succeeds if no evidence exists to prove the negative case.

---

## Running the Compliance Check

To evaluate travel eligibility and generate explanations, load the file into SWI-Prolog:

{linenos=off}
~~~~~~~~
$ swipl compliance_check.pl
~~~~~~~~

Query the compliance checker for `alice`:

{linenos=off}
~~~~~~~~
?- run_compliance_check(alice).
~~~~~~~~

s(CASP) evaluates the logic, confirms `alice` is eligible, and outputs a natural language justification tree explaining its reasoning:

{linenos=off}
~~~~~~~~
alice is eligible.

Justification Tree:
   alice is eligible for travel reimbursement, because
      alice is a registered employee, and
      alice's trip was for business purposes, and
      there is no evidence that alice's trip was for personal reasons, and
      there is no evidence that alice has exceeded the travel expense limit of $500, because
         there is no evidence that alice's travel expense amount is $ any number not [350], and
         alice's travel expense amount is $ 350, and
         350 is less than or equal to 500
~~~~~~~~

If you run the query for `bob` or `charlie`, the check fails and outputs that they are not eligible. Bob's expense ($650) exceeds the $500 travel limit, while Charlie's trip was for personal travel, violating the compliance constraints.

---

## Key Design Decisions

**Why s(CASP) over regular Prolog?** Traditional Prolog handles negation using *negation-as-failure* (`\+`). However, regular Prolog cannot easily reason about negative constraints or construct explicit justification trees for negative constraints (e.g. proving that "there is no evidence that Alice's trip was for personal reasons"). s(CASP) handles stable model semantics and goal-directed Answer Set Programming, allowing it to mathematically prove that a negative condition is not met and represent that proof step in the justification output.

**Rules as Code movement.** Writing policies directly in executable code eliminates the translation gap between the legal draft of a policy and the software implementation. Government bodies and large enterprises are adopting this approach to ensure that business logic is auditable, self-documenting, and provably compliant.

## Optional Practice Problems

1. **Age-Restricted Access**: Extend the s(CASP) compliance rules in the `scasp_compliance` project to restrict access to certain services based on user age and regional jurisdiction.
2. **Conflict Resolution Query**: Write a query in `compliance_check.pl` to verify how s(CASP) resolves cases where two different compliance policies overlap and conflict.
