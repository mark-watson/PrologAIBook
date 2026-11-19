%% llm_extract.pl - Ask an LLM to extract entities and relations from
%% text, then load its JSON reply as Prolog facts.
:- module(llm_extract, [
    extract_facts/2,
    extraction_prompt/2
]).

:- use_module(json_to_facts).
:- use_module('../../llm_client/prolog/gemini').

%% extract_facts(+Text, -Counts)
%% Send Text to Gemini with an extraction prompt, asking for a JSON
%% reply, and assert the result with json_string_to_facts/2. Counts
%% is the dict that json_string_to_facts/2 returns. Fails if the call
%% fails; throws if the reply is not valid JSON.
extract_facts(Text, Counts) :-
    extraction_prompt(Text, Prompt),
    gemini_generate(Prompt, Json, [json(true), temperature(0.0)]),
    json_string_to_facts(Json, Counts).

%% extraction_prompt(+Text, -Prompt)
%% The prompt names the exact JSON schema and asks for lowercase,
%% underscore-separated predicates, so the facts are easy to query.
extraction_prompt(Text, Prompt) :-
    format(string(Prompt),
"Extract the people, organizations, and places in the text below, and the
relations between them. Reply with JSON only, using this schema:
{\"entities\": [{\"name\": \"...\", \"type\": \"person|organization|place\"}],
 \"relations\": [{\"subject\": \"...\", \"predicate\": \"...\", \"object\": \"...\"}]}
Use the entity names exactly as written in the text. Write each predicate
in lowercase with underscores, such as works_for or located_in.

Text: ~w", [Text]).
