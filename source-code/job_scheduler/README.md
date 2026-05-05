# Job Scheduler

Constraint-based job scheduling with temporal constraints using CLP(FD). Companion code for the Constraint Logic Programming chapter.

## Running Examples

```shell
cd source-code/job_scheduler
swipl -s load.pl
```

```prolog
?- schedule_jobs([job(a, 3, 10), job(b, 2, 8), job(c, 4, 20)], Schedule).
```

## Running Tests

```shell
swipl -g "['tests/test_scheduler.pl'], run_tests, halt" -s load.pl
```


## Architecture

![CLP(FD) constraint-based job scheduling with temporal constraints](FIG_job_scheduler.jpg)

## Description

Demonstrates a practical application of CLP(FD) for scheduling problems. Each job has a name, duration, and deadline. The scheduler creates constrained start/end time variables, enforces non-overlapping execution, respects deadlines, and uses `label/1` to find feasible schedules. This pattern extends naturally to real-world applications like production scheduling, resource allocation, and project planning — domains where Prolog's constraint-based approach offers significant advantages over imperative solutions.
