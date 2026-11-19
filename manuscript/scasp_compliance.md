# Explainable AI and Computational Law with s(CASP)

As software takes over more administrative and legal decisions, **Computational Law** (often called "Rules as Code") has grown. Its goal is to write laws, tax codes, company policies, and safety standards as programs that a computer can run.

Running the rules is only half the job. If a system denies someone a benefit, rejects an expense claim, or flags a payment for audit, it **must** be able to explain *why*.

Most machine learning models cannot give such explanations. Plain Prolog can build proof trees for goals that succeed, as we saw in the Reasoning chapter, but it has no proof to show when a goal fails, and failure is exactly what a denial is.

**s(CASP)** fills this gap. For each answer, it builds a **justification tree** that lists the rules and facts used and the exceptions it checked. It can justify negative answers too: it can explain why someone is *not* eligible.


{width: "80%"}
![Architecture diagram for the s(CASP) Compliance example](FIG_scasp_compliance.jpg)


## What is s(CASP)?

`s(CASP)` is a logic programming system that combines constraint logic programming with Answer Set Programming (ASP):
- **Goal-directed**: Classic ASP solvers compute whole models of a program up front, which is costly for large programs. s(CASP) answers one query at a time, like Prolog.
- **Justification trees**: It records which rules held and which exceptions it ruled out.
- **Natural language**: `#pred` templates turn goals into English phrases, so the justification tree prints as readable text.
- **Constructive negation**: `not G` is a goal in its own right, with its own proof. s(CASP) builds a *dual* program for each predicate that defines when it is false.

In SWI-Prolog, s(CASP) is a pack. Install it once with:

```prolog
?- pack_install(scasp).
```

---

## Implementing Compliance Rules

We model a company travel expense policy. A person is eligible for reimbursement if:
1. They are an employee.
2. The travel was for business purposes.
3. The travel was *not* for personal reasons.
4. They did *not* exceed their expense limit of $500.

Here is the file **scasp_compliance/compliance_check.pl**:

```prolog
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
```

The policy rules are ordinary Prolog syntax with one change: `not` replaces `\+`. `not personal_travel(Person)` holds when s(CASP) can show there is no evidence of personal travel.

The `#pred` templates use `@(Var)` to insert a variable's value. Keep each template string on one line: a line break inside the quotes would appear in the printed explanation.

`run_compliance_check/1` first asks s(CASP) to prove eligibility. If that fails, it asks s(CASP) to prove `not eligible_for_reimbursement(Person)`, which gives a justification for the denial. Two practical details:
- Each query runs inside `\+ \+`, which undoes its variable bindings when it finishes. With scasp 2.0.1, bindings left over from one query can make the next query raise an internal error.
- The human-readable output of scasp 2.0.1 contains the HTML entity `&(nbsp)` in comparisons, so the code replaces it with a space.

---

## Running the Compliance Check

Load the file into SWI-Prolog:

{linenos=off}
~~~~~~~~
$ swipl compliance_check.pl
~~~~~~~~

Query the compliance checker for `alice`:

{linenos=off}
~~~~~~~~
?- run_compliance_check(alice).
~~~~~~~~

s(CASP) confirms that `alice` is eligible and prints its justification:

{linenos=off}
~~~~~~~~
alice is eligible.

Justification Tree:
   alice is eligible for travel reimbursement, because
      alice is a registered employee, and
      alice's trip was for business purposes, and
      there is no evidence that alice's trip was for personal reasons, and
      there is no evidence that alice has exceeded the travel expense limit of $500, because
         there is no evidence that alice's travel expense amount is $any number not [350], and
         alice's travel expense amount is $350, and
         350 is less than or equal to 500
~~~~~~~~

The negative steps are the interesting part. To show that Alice did not exceed the limit, s(CASP) uses the dual of `travel_limit_exceeded/1`: for every expense amount Alice could have, the amount is at most 500. Her only recorded amount is 350, so there is no evidence of any other amount, and 350 is less than or equal to 500.

Now the denials. `make run` checks all three people:

{linenos=off}
~~~~~~~~
bob is NOT eligible.

Justification Tree:
   there is no evidence that bob is eligible for travel reimbursement, because
      bob is a registered employee, and
      bob's trip was for business purposes, and
      there is no evidence that bob's trip was for personal reasons, and
      bob has exceeded the travel expense limit of $500, because
         bob's travel expense amount is $650, and
         650 is greater than 500

charlie is NOT eligible.

Justification Tree:
   there is no evidence that charlie is eligible for travel reimbursement, because
      charlie is a registered employee, and
      charlie's trip was for business purposes, and
      charlie's trip was for personal reasons
~~~~~~~~

Each denial names the condition that failed: Bob's $650 claim is over the limit, and Charlie's trip was personal. This is the explanation an employee, or an auditor, would need. The tests in **tests/test_compliance.pl** check these results, and `make test` runs them.

---

## Key Design Decisions

**Why s(CASP) and not plain Prolog?** Plain Prolog's `\+ G` succeeds when `G` fails, but it records nothing about *why* `G` failed, and with unbound variables it can give wrong answers. s(CASP) treats `not G` as a goal with its own proof, built from the dual program. That is what lets it justify both "there is no evidence that Alice's trip was personal" and "Bob is not eligible".

**Rules as Code.** When a policy is written as code, there is no gap between the policy text and the software that applies it. Some governments and large companies use this approach so their rules are easy to audit and test.

**The cost.** s(CASP) is much slower than Prolog, and its explanations grow with the size of the proof. It suits rule sets of the size of a policy document, not large databases.

## Optional Practice Problems

1. **Manager Approval**: Add a rule that lets an employee over the limit still be reimbursed if `manager_approved(Person)` holds. Add a `#pred` template and a test that Bob becomes eligible once you add `manager_approved(bob)`.
2. **Who Is Eligible?**: Query `scasp(eligible_for_reimbursement(P), [])` with `P` unbound. How does s(CASP) answer, and how does it differ from Prolog's backtracking?
3. **Age and Region**: Write a new policy that restricts a service by the user's age and country, with different age limits per country, and print justifications for one approval and one denial.
