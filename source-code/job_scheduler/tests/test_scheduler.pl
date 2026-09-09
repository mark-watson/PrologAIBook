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

test(schedule_valid, [nondet]) :-
    Jobs = [job(a, 3, 5), job(b, 2, 6), job(c, 4, 10), job(d, 1, 11),
        job(e, 2, 13), job(f, 5, 18)],
    schedule_jobs(Jobs, Schedule),
    schedule_valid(Schedule).

test(schedule_valid_detects_overlap, [fail]) :-
    schedule_valid([scheduled(a, 0, 5), scheduled(b, 3, 7)]).

test(schedule_valid_accepts_nonoverlap) :-
    schedule_valid([scheduled(a, 0, 5), scheduled(b, 5, 7)]).

test(infeasible_input_fails, [fail]) :-
    % Total work is 6 time units but both jobs must finish by time 4.
    schedule_jobs([job(a, 3, 4), job(b, 3, 4)], _).

test(var_deadline_uses_duration_horizon, [nondet]) :-
    schedule_jobs([job(a, 3, _), job(b, 2, _)], Schedule),
    schedule_valid(Schedule).

:- end_tests(scheduler).

deadline_ok(job(_, _, Deadline), scheduled(_, _, End)) :- End =<
    Deadline.
