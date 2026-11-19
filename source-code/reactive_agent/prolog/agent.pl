%% agent.pl - A perception-reasoning-action loop for simple agents
:- module(agent, [
    run_agent/2,
    define_goal/1,
    register_tool/2,
    add_belief/1,
    remove_belief/1,
    belief/1,
    tool/2,
    goal/1,
    action_log/2,
    reset_agent/0
]).

:- dynamic goal/1.
:- dynamic tool/2.         % tool(Name, Goal): the goal that performs it
:- dynamic belief/1.       % the agent's current beliefs
:- dynamic action_log/2.   % action_log(Step, Action)

%% reset_agent
%% Forget goals, tools, beliefs, and the action log.
reset_agent :-
    retractall(goal(_)),
    retractall(tool(_, _)),
    retractall(belief(_)),
    retractall(action_log(_, _)).

%% define_goal(+Goal)
define_goal(G) :- assertz(goal(G)).

%% register_tool(+Name, :Goal)
%% Goal is called when the agent chooses the action Name.
:- meta_predicate register_tool(+, 0).
register_tool(Name, Goal) :- assertz(tool(Name, Goal)).

%% add_belief(+B) and remove_belief(+B) keep one copy of each belief.
add_belief(B) :- ( belief(B) -> true ; assertz(belief(B)) ).
remove_belief(B) :- retractall(belief(B)).

%% run_agent(+Agent, +MaxSteps)
%% Agent is the module that implements the agent. It must define
%%   perceive/0           update beliefs from the environment
%%   select_action/1      choose the name of a registered tool
%% Each step checks the goals first. The loop stops when every goal
%% is a belief, when no action applies, or after MaxSteps steps.
run_agent(Agent, MaxSteps) :-
    run_agent(Agent, 1, MaxSteps).

run_agent(_, Step, Max) :-
    Step > Max, !,
    format("Agent: stopped after ~w steps.~n", [Max]).
run_agent(Agent, Step, Max) :-
    Agent:perceive,
    (   all_goals_met
    ->  findall(G, goal(G), Gs),
        Done is Step - 1,
        format("Agent: goals ~w achieved after ~w actions.~n",
               [Gs, Done])
    ;   Agent:select_action(Action)
    ->  execute_action(Step, Action),
        Step1 is Step + 1,
        run_agent(Agent, Step1, Max)
    ;   format("Agent: no applicable action.~n")
    ).

all_goals_met :-
    forall(goal(G), belief(G)).

%% execute_action(+Step, +Action)
%% Run the tool registered for Action and log it. An action with no
%% registered tool is an error, which catches typos and, in an
%% LLM-driven agent, made-up tool names.
execute_action(Step, Action) :-
    (   tool(Action, Goal)
    ->  format("Agent: step ~w: ~w~n", [Step, Action]),
        assertz(action_log(Step, Action)),
        call(Goal)
    ;   existence_error(tool, Action)
    ).
