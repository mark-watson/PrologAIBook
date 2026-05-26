# Building AI Agents with Prolog

AI agents that reason, plan, and act autonomously are a major focus of modern AI research. Prolog's built-in support for logical reasoning, backtracking search, and knowledge representation makes it an excellent foundation for building intelligent agents.

{width: "80%"}
![Architecture diagram for the Reactive Agent example](FIG_reactive_agent.jpg)

## What Is an AI Agent?

An **AI agent** is a system that perceives its environment, reasons about what it observes, and takes actions to achieve its goals. Every agent, from a simple thermostat to a LLM-powered research assistant, follows the same fundamental pattern: the **perception-reasoning-action loop**.

1. **Perceive**: observe the environment. This could mean reading sensor data, parsing a user's natural language query, checking a database, or fetching the contents of a web page.
2. **Reason**: decide what to do next. The agent matches its observations against its goals and its knowledge of how the world works, then selects the best action.
3. **Act**: carry out the chosen action and feed the outcome back into the loop.

Prolog is a natural fit for agent architectures because its inference engine already implements a reasoning loop: given a goal, Prolog searches for a proof using the available rules and facts. Wrapping that inference engine inside a perception-action cycle produces a goal-directed agent with minimal code.

## A Simple Reactive Agent

A **reactive agent** responds directly to its current perceptions without maintaining an internal model of the world. It maps observations to actions using simple rules. While limited, a reactive agent is fast, predictable, and easy to debug — making it the right starting point before adding the complexity of planning, memory, or tool use.

The **reactive_agent** project implements a reusable reactive agent framework with a perception-reasoning-action loop. Here is the file **reactive_agent/prolog/agent.pl**:

```prolog
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

%% Extension points — override these for your domain
perceive :- true.

select_action(idle) :-
    format("Agent: no applicable action found.~n").

execute_action(idle) :- true.
execute_action(Action) :-
    get_time(T),
    assert(action_log(Action, T)),
    format("Agent: executing ~w~n", [Action]).
```

The module defines four dynamic predicates as the agent's working memory: `goal/1` stores the current objective, `tool/2` registers named actions the agent can take, `belief/1` holds facts the agent has learned, and `action_log/2` records every action with its timestamp for later analysis.

The core of the framework is `run_agent/1`. It takes a maximum step count and enters a loop: check whether the goal is already satisfied (in which case stop), then perceive the environment, select an action, execute it, decrement the counter, and recurse. The base case fires when the step counter reaches zero, preventing infinite loops.

The three predicates `perceive/0`, `select_action/1`, and `execute_action/1` are deliberately written as extension points. Out of the box, `perceive/0` does nothing, `select_action/1` falls back to `idle`, and `execute_action/1` logs the action with a timestamp. To build a working agent for a specific domain, you override these predicates in a separate module that imports `agent`.

### Extending the Framework

Suppose we want an agent that monitors a file system and responds to disk space warnings. We create a new module that imports `agent` and fills in the extension points:

```prolog
:- module(filesystem_agent, []).
:- use_module(prolog/agent).

perceive :-
    check_disk_space(PercentFree),
    (   PercentFree < 10
    ->  assert(belief(disk_low))
    ;   true
    ).

select_action(send_alert) :-
    retract(belief(disk_low)),
    tool(send_alert, _).
select_action(compress_logs) :-
    retract(belief(disk_low)),
    tool(compress_logs, _).

check_disk_space(P) :-
    /* platform-specific: call df or use OS bindings */
    P = 5.   % placeholder

:- define_goal(disk_ok).
:- register_tool(send_alert, alert_admin/0).
:- register_tool(compress_logs, rotate_logs/0).
```

This demonstrates the pattern: `perceive/0` populates `belief/1` with observations, and `select_action/1` matches beliefs against registered tools to pick the next step. The framework handles the loop, logging, and goal checking automatically.

### Running the Agent

Load the framework in SWI-Prolog and run:

```prolog
?- define_goal(answer_found).
?- register_tool(search, search_web/1).
?- run_agent(10).
```

The tests verify basic setup:

```prolog
:- begin_tests(agent).

test(register_tool) :-
    register_tool(search, search_web/1).

test(define_goal) :-
    define_goal(answer_found).

:- end_tests(agent).
```

## Goal-Directed Agents

A reactive agent responds to the immediate situation. A **goal-directed agent** goes further: it maintains an explicit representation of what it wants to achieve and uses that goal to guide every decision. The distinction matters because the same observation — "the disk is at 5% free space" — might lead to different actions depending on whether the goal is `keep_system_running` or `minimize_cost`.

In our framework, goals are first-class. The `goal/1` predicate stores the current objective, and `run_agent/1` checks it at the top of every loop iteration. When `goal(G), belief(G)` succeeds, the agent stops — the goal is achieved. This pattern generalizes to multiple goals by extending the check:

```prolog
all_goals_satisfied :-
    forall(goal(G), belief(G)).
```

Goal priorities are also straightforward to add. If goals conflict — say, `save_disk_space` and `keep_logs_verbose` — you order them with a priority argument:

```prolog
:- dynamic goal/2.   % goal(Priority, GoalTerm)

highest_unsatisfied_goal(G) :-
    findall(P-G, (goal(P, G), \+ belief(G)), Pairs),
    sort(Pairs, Sorted),
    reverse(Sorted, [_-G|_]).
```

Prolog's unification engine makes goal matching natural: a goal like `file_status(File, archived)` succeeds when the belief database contains a matching `belief(file_status('/var/log/syslog', archived))` fact. Variables in the goal term act as queries against the belief store.

## Tool-Using Agents with LLM Integration

The reactive agent pattern becomes far more capable when the agent can call external tools (web search, database queries, LLM APIs, file system operations) and when an LLM helps select which tool to use.

The architecture has three layers:

1. **Tool Registry**: Prolog facts (`tool/2`) mapping tool names to the predicates that implement them. Each tool is a Prolog predicate that the agent can call.
2. **Action Selection**: `select_action/1` queries the tool registry and the belief store to find applicable actions. In a simple agent, this is pure Prolog rule matching. In an LLM-augmented agent, the agent sends the list of available tools and the current beliefs to an LLM and asks it to pick the next action.
3. **Tool Execution**: `execute_action/1` calls the selected tool predicate and records the result as a new belief.

A richer `select_action/1` that uses an LLM to choose among registered tools looks like this:

```prolog
select_action(Action) :-
    findall(Name-Pred, tool(Name, Pred), Tools),
    findall(B, belief(B), Beliefs),
    format(atom(Prompt),
           'Available tools: ~w. Current beliefs: ~w. What action?',
           [Tools, Beliefs]),
    ollama_generate(Prompt, ActionAtom),
    term_string(Action, ActionAtom).
```

The LLM receives a description of the current state (beliefs) and a list of available tools, then returns the selected action as structured text. Prolog parses it back into a term and executes it. This combines the LLM's flexibility (understanding natural language goals, adapting to novel situations) with Prolog's reliability for tool execution and state management.

### Defining Tools

Tools are just Prolog predicates registered with `register_tool/2`:

```prolog
search_web(Query) :-
    http_get('https://api.duckduckgo.com/', Result, [q(Query), format(json)]),
    assert(belief(search_result(Query, Result))).

query_knowledge_base(Query) :-
    findall(R, knowledge(Query, R, _), Results),
    assert(belief(kb_result(Query, Results))).
```

Each tool predicate does its work and then asserts the result as a belief. This integrates the tool's output into the agent's state, making it available for the next round of reasoning and action selection.

## Multi-Agent Communication

When multiple agents operate in the same environment, they need to communicate, like sharing discoveries, delegating subtasks, and coordinating to avoid conflicting actions. Prolog's dynamic database is inherently shared within a process, which makes message passing between agents as simple as asserting and querying facts.

A minimal message-passing system uses a `message/3` dynamic predicate:

```prolog
:- dynamic message/3.   % message(Sender, Receiver, Content)

send_message(From, To, Content) :-
    assert(message(From, To, Content)).

receive_messages(Agent, Messages) :-
    findall(Msg, (retract(message(_, Agent, Msg))), Messages).
```

Each agent periodically calls `receive_messages/2` in its perception step, processing messages and updating its beliefs accordingly. Because messages are retracted when read, each is consumed exactly once — a simple but effective protocol.

For more sophisticated coordination, agents can use a **blackboard architecture**: a shared data structure (the blackboard) to which any agent can post partial results or hypotheses. Other agents watch the blackboard for data relevant to their expertise. Prolog's assert/retract mechanism implements a blackboard directly — agents assert findings as facts and other agents query those facts in their perception steps.

```prolog
%% Agent A: researcher
perceive :-
    receive_messages(researcher, Msgs),
    process_research_tasks(Msgs),
    (   belief(search_complete(Topic))
    ->  assert(blackboard(search_done(Topic)))   % post to blackboard
    ;   true
    ).

%% Agent B: summarizer — watches the blackboard
perceive :-
    findall(Topic, blackboard(search_done(Topic)), Topics),
    maplist(summarize_and_store, Topics).
```

Each agent is a specialization of the same `run_agent/1` loop, but with a different goal, tool set, and perception predicate. They run either interleaved in a single Prolog process or in separate threads using SWI-Prolog's `thread_create/2`.

## Case Study: A Research Assistant Agent

The **research_assistant** project sketches a multi-stage agent that answers research questions by chaining together web search, LLM summarization, and Prolog knowledge-base reasoning. Here is the file **research_assistant/prolog/assistant.pl**:

```prolog
%% assistant.pl - Research assistant agent
%% Combines: web search → LLM summarization → Prolog knowledge base →
%% reasoning
:- module(assistant, [
    research/2
]).

:- dynamic knowledge/3.  % knowledge(Topic, Fact, Source)

%% research(+Question, -Answer)
%% Full pipeline:
%% 1. Parse question to identify search terms
%% 2. Web search via REST API (Brave Search / Tavily)
%% 3. Summarize results via LLM (Gemini/Ollama)
%% 4. Store structured knowledge as Prolog facts
%% 5. Reason over knowledge base to produce answer
research(Question, Answer) :-
    format("Researching: ~w~n", [Question]),
    extract_search_terms(Question, Terms),
    web_search(Terms, Results),
    llm_summarize(Results, Summary),
    store_knowledge(Terms, Summary),
    reason_over_knowledge(Question, Answer).

extract_search_terms(Question, Terms) :-
    %% Use LLM to extract key terms from the question
    format(atom(Prompt),
           'Extract 3-5 key search terms from: "~w". Return as Prolog list.',
           [Question]),
    gemini_generate(Prompt, TermAtom),
    term_string(Terms, TermAtom).

web_search(Terms, Results) :-
    %% Call search API — see WebClient chapter for REST examples
    format("Would search for: ~w~n", [Terms]),
    Results = [placeholder_result(Terms)].

llm_summarize(Results, Summary) :-
    format(atom(Prompt),
           'Summarize these search results in 3 bullet points: ~w',
           [Results]),
    gemini_generate(Prompt, Summary).

store_knowledge(Topic, Summary) :-
    assert(knowledge(Topic, summary, Summary)).

reason_over_knowledge(Question, Answer) :-
    findall(Fact, knowledge(_, Fact, _), Facts),
    format(atom(Prompt),
           'Using these facts: ~w, answer: "~w"',
           [Facts, Question]),
    gemini_generate(Prompt, Answer).
```

The pipeline is explicit in the code: `research/2` chains five predicates, each handling one stage of the workflow. `extract_search_terms/2` uses an LLM to pull key terms from the natural-language question. `web_search/2` (a placeholder awaiting the Brave Search or Tavily API from the Web Clients chapter) fetches results. `llm_summarize/2` condenses the raw search results into a digest. `store_knowledge/3` asserts the summary into the `knowledge/3` dynamic database, where other Prolog rules can reason over it. Finally, `reason_over_knowledge/2` synthesizes an answer from the accumulated facts.

### Extending the Pipeline

The placeholder `web_search/2` is designed to be replaced with a real HTTP call to a search API. The Web Clients chapter covers `http_get/3` and JSON parsing in detail. Once connected, the pipeline becomes fully operational:

```prolog
web_search(Terms, Results) :-
    atomic_list_concat(Terms, '+', Query),
    format(atom(URL),
           'https://api.search.example.com/v1/search?q=~w',
           [Query]),
    http_get(URL, Results, [json_object(dict)]).
```

The research assistant also benefits from caching: if the same question (or similar search terms) was answered recently, the agent can return the cached knowledge rather than repeating the full pipeline. This is a natural fit for the Cache Engine chapter's patterns.

Running the assistant:

```prolog
?- research("What are the health benefits of green tea?", Answer).
Researching: What are the health benefits of green tea?
Answer = "Green tea contains antioxidants called catechins..."
```
