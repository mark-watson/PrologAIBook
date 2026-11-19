%% scheduler.pl - Job scheduling with temporal constraints using CLP(FD)
:- module(scheduler, [
    schedule_jobs/2,
    no_overlap/1,
    schedule_valid/1,
    makespan/2
]).

:- use_module(library(clpfd)).

%% schedule_jobs(+Jobs, -Schedule)
%% Jobs: list of job(Name, Duration, Deadline) terms. Deadline may
%% be unbound for a job with no deadline.
%% Schedule: list of scheduled(Name, Start, End) terms, in the same
%% order as Jobs, using one machine. The solver chooses the order in
%% which the jobs run. The first answer has the smallest makespan
%% (the time the last job ends). Infeasible inputs fail.
schedule_jobs(Jobs, Schedule) :-
    horizon(Jobs, Horizon),
    maplist(create_task(Horizon), Jobs, Schedule, Starts),
    maplist(deadline_constraint, Jobs, Schedule),
    no_overlap(Schedule),
    makespan(Schedule, Makespan),
    labeling([min(Makespan)], Starts).

%% horizon(+Jobs, -Horizon)
%% No job needs to start later than the total work: any feasible
%% schedule can be shifted left until it has no idle time.
horizon(Jobs, Horizon) :-
    foldl(add_duration, Jobs, 0, Horizon).

add_duration(job(_, Duration, _), Sum0, Sum) :-
    Sum is Sum0 + Duration.

create_task(Horizon, job(Name, Duration, _Deadline),
            scheduled(Name, Start, End), Start) :-
    Start in 0..Horizon,
    End #= Start + Duration.

deadline_constraint(job(_, _, Deadline), scheduled(_, _, End)) :-
    (   integer(Deadline)
    ->  End #=< Deadline
    ;   true
    ).

%% no_overlap(+Schedule)
%% Posts constraints so that no two jobs overlap: for each pair, one
%% job ends before the other starts. #\/ is a constraint
%% disjunction, so the solver decides the order by propagation and
%% search instead of by Prolog backtracking.
no_overlap([]).
no_overlap([Task|Tasks]) :-
    maplist(disjoint(Task), Tasks),
    no_overlap(Tasks).

disjoint(scheduled(_, S1, E1), scheduled(_, S2, E2)) :-
    E1 #=< S2 #\/ E2 #=< S1.

%% makespan(+Schedule, -Makespan)
%% Makespan is the largest end time in Schedule.
makespan(Schedule, Makespan) :-
    maplist(end_time, Schedule, Ends),
    max_list_fd(Ends, Makespan).

end_time(scheduled(_, _, End), End).

max_list_fd([E|Es], Max) :-
    foldl(fd_max, Es, E, Max).

fd_max(E, M0, M) :-
    M #= max(M0, E).

%% schedule_valid(+Schedule)
%% Verifies a fully ground schedule: no two jobs overlap.  Uses plain
%% numeric comparisons (no constraint posting) and fails if the
%% schedule contains variables.
schedule_valid(Schedule) :-
    maplist(ground, Schedule),
    \+ overlaps_any_pair(Schedule, Schedule).

overlaps_any_pair([S|_], All) :-
    overlaps_one(S, All).
overlaps_any_pair([_|Ss], All) :-
    overlaps_any_pair(Ss, All).

overlaps_one(S, All) :-
    member(T, All),
    S \== T,
    S = scheduled(_, StartS, EndS),
    T = scheduled(_, StartT, EndT),
    StartS < EndT,
    StartT < EndS.
