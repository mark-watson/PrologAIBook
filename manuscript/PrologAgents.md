# Building AI Agents with Prolog

AI agents that reason, plan, and act autonomously are a major focus of modern AI research. Prolog's built-in support for logical reasoning, backtracking search, and knowledge representation makes it an excellent foundation for building intelligent agents.

{width: "80%"}
![Architecture diagram for the Reactive Agent example](FIG_reactive_agent.jpg)

## What Is an AI Agent?

TBD: Defining agents in the AI sense — perception, reasoning, planning, and action. The agent loop.

## A Simple Reactive Agent

TBD: Implementing a basic stimulus-response agent in Prolog. Modeling the environment and the agent's perception-action cycle.

The **reactive_agent** project implements a goal-directed agent with a perception-reasoning-action loop. Here is the file **reactive_agent/prolog/agent.pl**:

```prolog
%% agent.pl - Goal-directed agent with perception-reasoning-action loop
:- module(agent, [
    run_agent/1, define_goal/1, register_tool/2
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

perceive :- true.

select_action(idle) :-
    format("Agent: no applicable action found.~n").

execute_action(idle) :- true.
execute_action(Action) :-
    get_time(T),
    assert(action_log(Action, T)),
    format("Agent: executing ~w~n", [Action]).
```

## Goal-Directed Agents

TBD: Agents that maintain goals and use Prolog's inference engine to determine actions that achieve those goals.

## Tool-Using Agents with LLM Integration

TBD: Building agents that combine LLM-based natural language understanding with Prolog-based tool selection and execution. Defining tools as Prolog predicates.

## Multi-Agent Communication

TBD: Implementing simple multi-agent systems where agents communicate via message passing and coordinate their reasoning.

## Case Study: A Research Assistant Agent

TBD: A practical agent that uses web search, LLM summarization, and Prolog knowledge base reasoning to answer research questions and explain its reasoning process.

The **research_assistant** project sketches this architecture. Here is the file **research_assistant/prolog/assistant.pl**:

```prolog
%% assistant.pl - Research assistant agent
%% Combines: web search -> LLM summarization -> Prolog KB -> reasoning
:- module(assistant, [research/2]).

:- dynamic knowledge/3.  % knowledge(Topic, Fact, Source)

%% research(+Question, -Answer)
%% Pipeline:
%% 1. Parse question to identify search terms
%% 2. Web search via REST API (Brave Search / Tavily)
%% 3. Summarize results via LLM (Gemini/Ollama)
%% 4. Store structured knowledge as Prolog facts
%% 5. Reason over knowledge base to produce answer
research(Question, Answer) :-
    format("Researching: ~w~n", [Question]),
    Answer = placeholder_answer(Question).
```
