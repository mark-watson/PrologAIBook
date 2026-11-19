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
