%% scheduler.pl - Job scheduling with temporal constraints using CLP(FD)
:- module(scheduler, [
    schedule_jobs/2,
    no_overlap/1
]).

:- use_module(library(clpfd)).

%% schedule_jobs(+Jobs, -Schedule)
%% Jobs: list of job(Name, Duration, Deadline) terms
%% Schedule: list of scheduled(Name, Start, End) terms
schedule_jobs(Jobs, Schedule) :-
    maplist(create_task, Jobs, Schedule, Starts),
    chain(Starts, #=<),  % order tasks by start time
    maplist(deadline_constraint, Jobs, Schedule),
    no_overlap(Schedule),
    maplist(label_task, Schedule).

create_task(job(Name, Duration, _Deadline), scheduled(Name, Start, End), Start) :-
    Start in 0..100,
    End #= Start + Duration.

deadline_constraint(job(Name, _Duration, Deadline), scheduled(Name, _Start, End)) :-
    End #=< Deadline.

no_overlap([]).
no_overlap([_]).
no_overlap([scheduled(_,_,End1)|Rest]) :-
    Rest = [scheduled(_,Start2,_)|_],
    End1 #=< Start2,
    no_overlap(Rest).

label_task(scheduled(_, Start, _)) :- label([Start]).
