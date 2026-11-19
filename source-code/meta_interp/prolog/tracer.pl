%% tracer.pl - A meta-interpreter that prints a structured trace
:- module(tracer, [
    mi_trace/1,
    mi_trace/2
]).

%% mi_trace(+Goal)
%% mi_trace(+Module, +Goal)
%% Solve Goal like Prolog does, printing CALL, EXIT, and FAIL lines
%% indented by depth. Built-in goals are shown on one line.
mi_trace(Goal) :-
    mi_trace(user, Goal).

mi_trace(Mod, Goal) :-
    trace_goal(Mod, Goal, 0).

trace_goal(_, true, _) :- !.
trace_goal(Mod, (A, B), D) :- !,
    trace_goal(Mod, A, D),
    trace_goal(Mod, B, D).
trace_goal(Mod, G, D) :-
    predicate_property(Mod:G, built_in), !,
    (   call(Mod:G)
    ->  report(D, 'BUILTIN', G)
    ;   report(D, 'FAIL', G),
        fail
    ).
trace_goal(Mod, G, D) :-
    report(D, 'CALL', G),
    D1 is D + 1,
    (   clause(Mod:G, Body),
        trace_goal(Mod, Body, D1),
        report(D, 'EXIT', G)
    ;   report(D, 'FAIL', G),
        fail
    ).

report(Depth, Port, Goal) :-
    Indent is Depth * 2,
    format("~t~*|~w ~p~n", [Indent, Port, Goal]).
