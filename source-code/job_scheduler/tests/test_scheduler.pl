:- module(test_scheduler, []).
:- use_module(library(plunit)).
:- use_module('../prolog/scheduler').

:- begin_tests(scheduler).

test(schedule_three_jobs, [nondet]) :-
    Jobs = [job(a, 3, 10), job(b, 2, 8), job(c, 4, 20)],
    schedule_jobs(Jobs, Schedule),
    length(Schedule, 3).

:- end_tests(scheduler).
