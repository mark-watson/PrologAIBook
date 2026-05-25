%% assistant.pl - Research assistant agent
%% Combines: web search → LLM summarization → Prolog knowledge base →
%% reasoning
:- module(assistant, [
    research/2
]).

:- dynamic knowledge/3.  % knowledge(Topic, Fact, Source)

%% research(+Question, -Answer)
%% TBD: Full implementation combining:
%% 1. Parse question to identify search terms
%% 2. Web search via REST API (Brave Search / Tavily)
%% 3. Summarize results via LLM (Gemini/Ollama)
%% 4. Store structured knowledge as Prolog facts
%% 5. Reason over knowledge base to produce answer
research(Question, Answer) :-
    format("Researching: ~w~n", [Question]),
    %% Placeholder: direct LLM query
    Answer = placeholder_answer(Question).

%% TBD: Implement search, summarize, store, reason pipeline
