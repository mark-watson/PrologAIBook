:- module(test_scheduler, []).
:- use_module(library(plunit)).
:- use_module('../prolog/scheduler').

:- begin_tests(scheduler).

test(schedule_three_jobs, [nondet]) :-
    Jobs = [job(a, 3, 10), job(b, 2, 8), job(c, 4, 20)],
    schedule_jobs(Jobs, Schedule),
    length(Schedule, 3).

test(schedule_six_jobs, [nondet]) :-
    Jobs = [job(a, 3, 5), job(b, 2, 6), job(c, 4, 10), job(d, 1, 11),
        job(e, 2, 13), job(f, 5, 18)],
    schedule_jobs(Jobs, Schedule),
    length(Schedule, 6).

test(deadlines_respected, [nondet]) :-
    Jobs = [job(a, 3, 5), job(b, 2, 6), job(c, 4, 10), job(d, 1, 11),
        job(e, 2, 13), job(f, 5, 18)],
    schedule_jobs(Jobs, Schedule),
    maplist(deadline_ok, Jobs, Schedule).

test(no_overlap, [nondet]) :-
    Jobs = [job(a, 3, 5), job(b, 2, 6), job(c, 4, 10), job(d, 1, 11),
        job(e, 2, 13), job(f, 5, 18)],
    schedule_jobs(Jobs, Schedule),
    no_overlap(Schedule).

:- end_tests(scheduler).

deadline_ok(job(_, _, Deadline), scheduled(_, _, End)) :- End =<
    Deadline.
