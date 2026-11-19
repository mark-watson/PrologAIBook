# Explainable AI & Computational Law with s(CASP)

This project demonstrates how to implement **Explainable AI (XAI)** and **Computational Law (Rules as Code)** using the `s(CASP)` reasoning engine.

## Why This Project is Useful
Traditional machine learning algorithms act as "black boxes": they output predictions but cannot explain the reasoning behind them. In safety-critical or regulated domains (e.g., law, tax compliance, healthcare), decisions must be auditable and explainable.

`s(CASP)` (Goal-Directed Answer Set Programming) is a modern logic programming system that solves this by generating **justification trees** (proof trees). When a compliance rule is evaluated, the system doesn't just output `true` or `false`; it constructs an explicit, human-readable trace detailing exactly which policies and facts were satisfied, and which exceptions were evaluated but not met. It can also justify a negative answer, such as why a person is *not* eligible.

## Tools & Libraries Used
- **SWI-Prolog**: The execution environment.
- **`library(scasp)`**: The SWI-Prolog library for goal-directed Answer Set Programming.

## Project Architecture
Refer to the architecture diagram for an overview of the system flow:

![scasp_compliance Architecture](architecture.jpg)

## How to Run the Example
Install the s(CASP) pack once:
```bash
swipl -g "pack_install(scasp), halt"
```

Then run the examples and tests:
```bash
make run
make test
```

Or start SWI-Prolog, load the file, and query the compliance check:
```prolog
?- run_compliance_check(alice).
?- run_compliance_check(bob).
```

Output for `bob`, who is denied:
```text
bob is NOT eligible.

Justification Tree:
   there is no evidence that bob is eligible for travel reimbursement, because
      bob is a registered employee, and
      bob's trip was for business purposes, and
      there is no evidence that bob's trip was for personal reasons, and
      bob has exceeded the travel expense limit of $500, because
         bob's travel expense amount is $650, and
         650 is greater than 500
```
