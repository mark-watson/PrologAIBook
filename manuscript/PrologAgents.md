# Building AI Agents with Prolog

AI agents that reason, plan, and act on their own are a major focus of AI work today. Prolog's reasoning, backtracking search, and knowledge representation make it a good base for building them. In this chapter we build a small agent framework, add goals, tools, and messages between agents, and finish with a research assistant that combines web search, a Prolog knowledge base, and an LLM.

{width: "80%"}
![Architecture diagram for the Reactive Agent example](FIG_reactive_agent.jpg)

## What Is an AI Agent?

An **AI agent** perceives its environment, reasons about what it observes, and acts to reach its goals. Every agent, from a thermostat to an LLM-powered research assistant, follows the same **perception-reasoning-action loop**:

1. **Perceive**: observe the environment. This could mean reading sensor data, parsing a user's natural language query, checking a database, or fetching the contents of a web page.
2. **Reason**: decide what to do next. The agent matches its observations against its goals and its knowledge of how the world works, then selects the best action.
3. **Act**: carry out the chosen action and feed the outcome back into the loop.

Prolog's inference engine already does the middle step: given a goal, it searches for a proof using rules and facts. Wrapping it in a perceive-act cycle gives an agent with little code.

## A Simple Reactive Agent

A **reactive agent** chooses its action from what it perceives now, using condition-action rules, with little or no memory. Reactive agents are fast, predictable, and easy to debug, so they are the right place to start before adding planning or tool use.

The **reactive_agent** project has two parts: a small framework and an example agent. Here is the framework, **reactive_agent/prolog/agent.pl**:

```prolog
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
```

The dynamic predicates are the agent's working memory: `goal/1` holds what it wants, `belief/1` what it knows, `tool/2` the actions it can take, and `action_log/2` what it has done.

`run_agent(Agent, MaxSteps)` runs the loop. Each step calls `Agent:perceive`, stops if every goal is now a belief, and otherwise calls `Agent:select_action(Action)` and runs the tool registered for that action. The loop also stops when no action applies or after `MaxSteps` steps.

Why pass the agent's module name? The framework cannot simply call `perceive` and let another module "override" it: in SWI-Prolog's module system, a call inside `agent` to `perceive` looks for `agent:perceive`, not a predicate of the same name in some other module. Calling `Agent:perceive` with the module as an argument says exactly which code to run. (Multifile hook predicates are the other common way to do this.)

`execute_action/2` refuses an action with no registered tool. This catches typing mistakes, and it matters more when an LLM chooses the action, as we will see.

### The Vacuum World

The classic first example of a reactive agent is the vacuum cleaner world from Russell and Norvig's *Artificial Intelligence: A Modern Approach*. There are two rooms, `a` and `b`, either of which may be dirty. The robot can suck up dirt, move left, or move right, and it can only sense its own room. Here is **reactive_agent/prolog/vacuum_world.pl**:

```prolog
%% vacuum_world.pl - The two-room vacuum cleaner world, a classic
%% reactive agent example
:- module(vacuum_world, [
    setup_world/2,
    perceive/0,
    select_action/1
]).

:- use_module(agent).

%% The environment: where the robot is, and which rooms are dirty.
:- dynamic robot_at/1, dirty/1.

%% setup_world(+Room, +DirtyRooms)
%% Put the robot in Room (a or b), make DirtyRooms dirty, and set up
%% the agent's goal and tools.
setup_world(Room, DirtyRooms) :-
    reset_agent,
    retractall(robot_at(_)),
    retractall(dirty(_)),
    assertz(robot_at(Room)),
    forall(member(R, DirtyRooms), assertz(dirty(R))),
    define_goal(all_clean),
    register_tool(suck, suck),
    register_tool(move_left, move_to(a)),
    register_tool(move_right, move_to(b)).

%% perceive: the robot senses only its own room. It remembers which
%% rooms it has seen clean.
perceive :-
    robot_at(Room),
    remove_belief(location(_)),
    add_belief(location(Room)),
    (   dirty(Room)
    ->  remove_belief(clean(Room)),
        add_belief(dirty(Room))
    ;   remove_belief(dirty(Room)),
        add_belief(clean(Room))
    ),
    (   belief(clean(a)), belief(clean(b))
    ->  add_belief(all_clean)
    ;   remove_belief(all_clean)
    ).

%% select_action(-Action): condition-action rules, tried in order.
select_action(suck) :-
    belief(location(R)), belief(dirty(R)), !.
select_action(move_right) :-
    belief(location(a)), \+ belief(clean(b)), !.
select_action(move_left) :-
    belief(location(b)), \+ belief(clean(a)), !.

%% The tools change the environment, not the beliefs; the agent sees
%% the result at its next perceive step.
suck :-
    robot_at(Room),
    retractall(dirty(Room)).

move_to(Room) :-
    retractall(robot_at(_)),
    assertz(robot_at(Room)).
```

The module keeps the *environment* (`robot_at/1`, `dirty/1`) apart from the agent's *beliefs*. The tools change the environment; the agent learns about the change only at its next `perceive` step, as a real robot would. `perceive/0` also records what the robot has seen: once it has seen both rooms clean, it believes `all_clean`, which is its goal.

`select_action/1` holds three condition-action rules: suck if this room is dirty, otherwise go to the other room if it has not been seen clean. The cuts make the first matching rule win.

### Running the Agent

```prolog
?- setup_world(a, [a, b]), run_agent(vacuum_world, 10).
Agent: step 1: suck
Agent: step 2: move_right
Agent: step 3: suck
Agent: goals [all_clean] achieved after 3 actions.
```

The tests check other starting states. Starting in a clean room `a` with nothing dirty, the robot still moves once, because it cannot know room `b` is clean without looking. That is the price of limited perception.

## Goal-Directed Agents

A reactive agent responds to the situation in front of it. A **goal-directed agent** keeps an explicit goal and lets it guide each choice. The same observation, "the disk has 5% free space", can call for different actions when the goal is `keep_system_running` than when it is `minimize_cost`.

In our framework, goals are data. `run_agent/2` checks them on every step with `all_goals_met/0`:

```prolog
all_goals_met :-
    forall(goal(G), belief(G)).
```

Priorities are easy to add. If goals conflict, such as `save_disk_space` and `keep_logs_verbose`, give each a priority:

```prolog
:- dynamic goal/2.   % goal(Priority, GoalTerm)

highest_unsatisfied_goal(G) :-
    findall(P-G, (goal(P, G), \+ belief(G)), Pairs),
    sort(Pairs, Sorted),
    reverse(Sorted, [_-G|_]).
```

Unification makes goals flexible: a goal such as `file_status(File, archived)` is met by any belief that matches it, such as `belief(file_status('/var/log/syslog', archived))`. Variables in a goal act as queries against the beliefs.

## Tool-Using Agents with LLM Integration

An agent becomes far more useful when it can call tools (web search, databases, LLM APIs, the file system) and when an LLM helps choose which tool to use. Our framework already has the three layers this needs:

1. **Tool registry**: `tool(Name, Goal)` facts map each action name to the goal that performs it.
2. **Action selection**: `select_action/1` picks an action name. In the vacuum world it is pure Prolog rules. In an LLM-driven agent, it shows the LLM the tool names and the current beliefs and asks for the next action.
3. **Execution**: the framework runs the tool's goal, which records its result as beliefs.

Here is an LLM-driven `select_action/1` for an agent module. Note the last two lines:

```prolog
select_action(Action) :-
    findall(Name, tool(Name, _), Names),
    findall(B, belief(B), Beliefs),
    format(string(Prompt),
           "Tools: ~w~nBeliefs: ~w~nReply with the name of the one tool to use next.",
           [Names, Beliefs]),
    gemini_generate(Prompt, Reply, [temperature(0.0)]),
    normalize_space(atom(Action), Reply),
    memberchk(Action, Names).
```

The reply is text, and an LLM may answer with a tool that does not exist, or with a whole sentence. So the code trims the reply to an atom and accepts it only if it is a registered tool name; otherwise `select_action/1` fails and the agent stops. Never turn LLM text into a Prolog goal with `term_string/2` and call it: that would let the model run any Prolog code it likes. The LLM chooses; Prolog checks and executes.

### Defining Tools

A tool is any Prolog goal. Using predicates from the research assistant later in this chapter:

```prolog
search_wikipedia(Query) :-
    assistant:wiki_search(Query, 3, Titles),
    add_belief(search_results(Query, Titles)).

read_page(Title) :-
    assistant:ensure_knowledge(Title),
    add_belief(read(Title)).

:- register_tool(search, search_wikipedia('Warren Abstract Machine')).
```

Each tool does its work and records the result as a belief, which the next `perceive` and `select_action` steps can use.

## Multi-Agent Communication

Agents that share an environment need to communicate: to share findings, hand off subtasks, and avoid getting in each other's way. All threads in a Prolog process share the dynamic database, so agents can pass messages by asserting and retracting facts.

A minimal message-passing system uses a `message/3` dynamic predicate:

```prolog
:- dynamic message/3.   % message(Sender, Receiver, Content)

send_message(From, To, Content) :-
    assert(message(From, To, Content)).

receive_messages(Agent, Messages) :-
    findall(Msg, (retract(message(_, Agent, Msg))), Messages).
```

Each agent calls `receive_messages/2` in its perception step and updates its beliefs. Because reading a message retracts it, each message is consumed once.

For looser coordination, agents can share a **blackboard**: a common store where any agent posts partial results, and other agents look for results they can use. In Prolog the blackboard is just a dynamic predicate:

```prolog
%% Agent A: researcher
perceive :-
    receive_messages(researcher, Msgs),
    process_research_tasks(Msgs),
    (   belief(search_complete(Topic))
    ->  assert(blackboard(search_done(Topic)))   % post to blackboard
    ;   true
    ).

%% Agent B: summarizer, watches the blackboard
perceive :-
    findall(Topic, blackboard(search_done(Topic)), Topics),
    maplist(summarize_and_store, Topics).
```

Each agent is its own module with its own `perceive/0` and `select_action/1`, run by the same `run_agent/2` loop. The agents can take turns in one thread or run in separate threads with `thread_create/2`. With threads, use `with_mutex/2` around code that reads and then changes shared facts, or SWI-Prolog's message queues (`thread_send_message/2`, `thread_get_message/1`), which handle the locking for you. Note also that our framework keeps one shared set of goals and beliefs, so a real multi-agent system would give each agent its own, for example by adding the agent's name as an argument.

## Case Study: A Research Assistant Agent

The **research_assistant** project answers research questions in four stages: it searches Wikipedia, stores what it finds as Prolog facts, and then asks an LLM to answer from those facts only, citing them. Here is **research_assistant/prolog/assistant.pl**:

```prolog
%% assistant.pl - Research assistant: web search, a Prolog knowledge
%% base, and an LLM that answers from that knowledge with citations
:- module(assistant, [
    research/2,
    research/3,
    search_terms/2,
    knowledge/3,
    clear_knowledge/0
]).

:- use_module(library(http/http_open)).
:- use_module(library(json)).
:- use_module(library(uri)).
:- use_module(library(option)).
:- use_module('../../llm_client/prolog/gemini').

:- dynamic knowledge/3.   % knowledge(Title, Summary, SourceURL)

clear_knowledge :- retractall(knowledge(_, _, _)).

%% research(+Question, -Answer)
%% research(+Question, -Answer, +Options)
%% 1. Turn the question into search terms.
%% 2. Search Wikipedia for matching pages.
%% 3. Store each page summary as a knowledge/3 fact (a page already
%%    in the knowledge base is not fetched again).
%% 4. Ask Gemini to answer from those facts only, citing them as [n].
%% Options: max_pages(N) (default 3), llm(false) to skip step 4 and
%% return the summaries instead.
research(Question, Answer) :-
    research(Question, Answer, []).

research(Question, Answer, Options) :-
    option(max_pages(Max), Options, 3),
    search_terms(Question, Query),
    format("Searching Wikipedia for: ~w~n", [Query]),
    wiki_search(Query, Max, Titles),
    Titles \== [],
    maplist(ensure_knowledge, Titles),
    findall(T-S-U, ( member(T, Titles), knowledge(T, S, U) ), Facts),
    (   option(llm(false), Options)
    ->  Answer = Facts
    ;   answer_from_facts(Question, Facts, Answer)
    ).

%% ---- Step 1: search terms ----

%% search_terms(+Question, -Query)
%% Drop question words and other common words, keeping the rest.
search_terms(Question, Query) :-
    split_string(Question, " ", " ?.,!", Words0),
    exclude(==(""), Words0, Words1),
    exclude(common_word, Words1, Words),
    atomic_list_concat(Words, ' ', Query).

common_word(W) :-
    string_lower(W, L),
    memberchk(L, ["what", "who", "when", "where", "why", "how", "is",
                  "are", "was", "were", "the", "a", "an", "of", "do",
                  "does", "did", "in", "on", "for", "to", "and",
                  "tell", "me", "about"]).

%% ---- Step 2: search ----

%% wiki_search(+Query, +Max, -Titles)
%% Titles of the top Max Wikipedia pages for Query.
wiki_search(Query, Max, Titles) :-
    uri_encoded(query_value, Query, Q),
    format(atom(URL),
           'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=~w&srlimit=~w&format=json',
           [Q, Max]),
    get_json(URL, Reply),
    findall(T, ( member(Hit, Reply.query.search),
                 get_dict(title, Hit, T) ),
            Titles).

%% ---- Step 3: knowledge base ----

ensure_knowledge(Title) :-
    knowledge(Title, _, _), !.
ensure_knowledge(Title) :-
    wiki_summary(Title, Summary, URL),
    assertz(knowledge(Title, Summary, URL)).

%% wiki_summary(+Title, -Summary, -URL)
%% The first paragraph of a Wikipedia page, from the REST API.
wiki_summary(Title, Summary, PageURL) :-
    atomic_list_concat(Parts, ' ', Title),
    atomic_list_concat(Parts, '_', Underscored),
    uri_encoded(path, Underscored, Path),
    format(atom(URL),
           'https://en.wikipedia.org/api/rest_v1/page/summary/~w', [Path]),
    get_json(URL, Reply),
    get_dict(extract, Reply, Summary),
    PageURL = Reply.content_urls.desktop.page.

%% get_json(+URL, -Dict)
%% Wikipedia asks API clients to send a User-Agent that names them.
get_json(URL, Dict) :-
    setup_call_cleanup(
        http_open(URL, In,
                  [ request_header('User-Agent'=
                        'PrologAIBook-ResearchAssistant/1.0 (book example)'),
                    timeout(20) ]),
        json_read_dict(In, Dict),
        close(In)).

%% ---- Step 4: answer ----

%% answer_from_facts(+Question, +Facts, -Answer)
%% The prompt numbers each fact, tells the model to use only these
%% sources, and to cite them as [n]. Answer ends with the source list.
answer_from_facts(Question, Facts, Answer) :-
    numbered_sources(Facts, 1, SourceText, RefText),
    format(string(Prompt),
"Answer the question using ONLY the numbered sources below. Cite the
sources you use as [1], [2], and so on. If the sources do not contain
the answer, say so.

Sources:
~w
Question: ~w", [SourceText, Question]),
    gemini_generate(Prompt, Reply, [temperature(0.2)]),
    format(string(Answer), "~w~n~nSources:~n~w", [Reply, RefText]).

numbered_sources([], _, "", "").
numbered_sources([T-S-U|Rest], N, Src, Refs) :-
    N1 is N + 1,
    numbered_sources(Rest, N1, Src1, Refs1),
    format(string(Src), "[~w] ~w: ~w~n~w", [N, T, S, Src1]),
    format(string(Refs), "[~w] ~w~n~w", [N, U, Refs1]).
```

Each stage is a short predicate:

1. **Search terms.** `search_terms/2` drops question words such as *what* and *is*. Search engines do better with the content words alone.
2. **Search.** `wiki_search/3` calls the Wikipedia search API, which needs no key. `uri_encoded/3` makes the query safe to put in a URL. Wikipedia asks API clients to identify themselves, so `get_json/2` sends a `User-Agent` header.
3. **Knowledge base.** `ensure_knowledge/1` stores each page summary as a `knowledge(Title, Summary, URL)` fact. A page already stored is not fetched again, so the knowledge base doubles as a cache, and you can query it like any Prolog facts.
4. **Answer.** `answer_from_facts/3` numbers the facts and tells Gemini to use only them and to cite them as `[n]`. Limiting the model to retrieved sources, an approach often called *retrieval-augmented generation*, makes answers easier to check and less likely to be invented. The source list in the answer comes from the Prolog facts, not from the model, so the URLs are real.

`make run` asks one question (it needs network access and `GOOGLE_API_KEY`):

```text
Searching Wikipedia for: designed Warren Abstract Machine
David H. D. Warren designed the Warren Abstract Machine in 1983 [1].

Sources:
[1] https://en.wikipedia.org/wiki/Warren_Abstract_Machine
[2] https://en.wikipedia.org/wiki/Abstract_machine
[3] https://en.wikipedia.org/wiki/David_H._D._Warren
```

With the option `llm(false)`, `research/3` returns the `Title-Summary-URL` facts instead of an answer, which is useful for testing and for programs that reason over the facts themselves.

The assistant runs its stages in a fixed order. To turn it into an agent in the sense of this chapter, register `search_wikipedia/1` and `read_page/1` as tools and let `select_action/1` decide what to do next, for example reading more pages when the summaries do not answer the question. Practice problem 2 asks you to do this.

## Optional Practice Problems

1. **A Bigger Vacuum World**: Extend `vacuum_world.pl` to a row of four rooms, with `move_left` and `move_right` moving one room at a time. Change the beliefs and rules so the robot cleans every room, and add a test.
2. **An Agent That Researches**: Write an agent module that uses `run_agent/2` with the tools `search` and `read` built on the research assistant's predicates. Its goal is `answered`, which `perceive/0` adds once at least two pages have been read.
3. **arXiv Search**: Add a `arxiv_search/3` predicate to the research assistant that queries the arXiv API (`http://export.arxiv.org/api/query?search_query=...`), parses the Atom XML reply with `load_xml/3`, and stores titles and abstracts as `knowledge/3` facts.
