# Medical Diagnosis

A symptom-based medical diagnosis system demonstrating reasoning with explanation. Companion code for the Reasoning and Inference chapter.

## Running Examples

```shell
cd source-code/medical_diagnosis
swipl -s load.pl
```

```prolog
?- diagnose([fever, cough, fatigue, body_aches], Result).
?- diagnose([sneezing, runny_nose, sore_throat], Result).
```

## Running Tests

```shell
swipl -g "load_test_files([]), run_tests, halt" -s load.pl
```

## Description

A practical case study applying Prolog reasoning to medical diagnosis. The system maintains a knowledge base of diseases and their required symptoms, then matches a patient's symptom list against disease profiles using `subset/2`. When a match is found, it returns a `diagnosis(Disease, Explanation)` term that includes the matching symptoms. This demonstrates how Prolog's pattern matching and logical inference naturally support diagnostic reasoning — a domain where expert systems have historically excelled.
