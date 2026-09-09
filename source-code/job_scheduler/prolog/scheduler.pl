%% scheduler.pl - Job scheduling with temporal constraints using CLP(FD)
:- module(scheduler, [
    schedule_jobs/2,
    no_overlap/1,
    schedule_valid/1
]).

:- use_module(library(clpfd)).

%% schedule_jobs(+Jobs, -Schedule)
%% Jobs: list of job(Name, Duration, Deadline) terms
%% Schedule: list of scheduled(Name, Start, End) terms
%%
%% The search horizon is derived from the input jobs: it is the
%% largest deadline in the input (or, if no job gives a deadline,
%% the sum of all durations, plus one as a safety margin).  Infeasible
%% inputs simply fail during labelling.
schedule_jobs(Jobs, Schedule) :-
    compute_horizon(Jobs, Horizon),
    maplist(create_task(Horizon), Jobs, Schedule, Starts),
    chain(Starts, #=<),  % order tasks by start time
    maplist(deadline_constraint, Jobs, Schedule),
    no_overlap(Schedule),
    maplist(label_task, Schedule).

%% compute_horizon(+Jobs, -Horizon)
compute_horizon(Jobs, Horizon) :-
    compute_horizon(Jobs, 0, 0, 0, Horizon).

compute_horizon([], MaxDeadline, TotalDuration, SeenDeadline,
    Horizon) :-
    (   SeenDeadline > 0
    ->  Horizon = MaxDeadline
    ;   Horizon is TotalDuration + 1
    ).
compute_horizon([job(_, Duration, Deadline)|Jobs], MaxD0, Total0,
    Seen0, Horizon) :-
    Total1 is Total0 + Duration,
    (   integer(Deadline)
    ->  MaxD1 is max(MaxD0, Deadline),
        Seen1 is Seen0 + 1
    ;   MaxD1 = MaxD0,
        Seen1 = Seen0
    ),
    compute_horizon(Jobs, MaxD1, Total1, Seen1, Horizon).

create_task(Horizon, job(Name, Duration, _Deadline),
    scheduled(Name, Start, End), Start) :-
    Start in 0..Horizon,
    End #= Start + Duration.

deadline_constraint(job(Name, _Duration, Deadline), scheduled(Name,
    _Start, End)) :-
    End #=< Deadline.

%% no_overlap(+Schedule)
%% Posts CLP(FD) constraints chaining adjacent jobs in the schedule
%% list: the end of each job must be =< the start of the next one.
%% NOTE: this operates on constraint variables while building the
%% schedule (it posts `#=<` constraints); it is NOT a check on ground
%% data.  Use schedule_valid/1 to verify a fully ground schedule.
no_overlap([]).
no_overlap([_]).
no_overlap([scheduled(_,_,End1)|Rest]) :-
    Rest = [scheduled(_,Start2,_)|_],
    End1 #=< Start2,
    no_overlap(Rest).

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

label_task(scheduled(_, Start, _)) :- label([Start]).
