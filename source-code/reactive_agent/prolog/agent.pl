%% agent.pl - Goal-directed agent with perception-reasoning-action loop
:- module(agent, [
    run_agent/1,
    define_goal/1,
    register_tool/2
]).

:- dynamic goal/1.
:- dynamic tool/2.         % tool(Name, Predicate)
:- dynamic belief/1.       % agent's current beliefs
:- dynamic action_log/2.   % action_log(Action, Timestamp)

%% define_goal(+Goal)
define_goal(G) :- assert(goal(G)).

%% register_tool(+Name, +Predicate)
register_tool(Name, Pred) :- assert(tool(Name, Pred)).

%% run_agent(+MaxSteps) - Main agent loop
run_agent(0) :- format("Agent: max steps reached.~n").
run_agent(N) :-
    N > 0,
    (   goal(G), belief(G)
    ->  format("Agent: goal ~w achieved!~n", [G])
    ;   perceive,
        select_action(Action),
        execute_action(Action),
        N1 is N - 1,
        run_agent(N1)
    ).

%% TBD: Implement perceive, select_action, execute_action
perceive :- true.

select_action(idle) :-
    format("Agent: no applicable action found.~n").

execute_action(idle) :- true.
execute_action(Action) :-
    get_time(T),
    assert(action_log(Action, T)),
    format("Agent: executing ~w~n", [Action]).
