# LLM Integration

Large language models (LLMs) are changing AI. Prolog makes a good partner for them: an LLM reads and writes text, and Prolog reasons over the facts that text contains, with explanations. In this chapter we call LLMs from Prolog, turn their answers into Prolog facts, and build a pipeline that mixes statistical NLP with Prolog rules.

## Calling LLM APIs from Prolog

With the HTTP client libraries from the Web Clients chapter, an LLM API is just another REST API:
1. Read the API key from an environment variable with `getenv/2`.
2. Build the JSON request as a Prolog dict.
3. Send it with `http_post/4`, which serializes the dict and parses the JSON reply into a dict.
4. Pull the generated text out of the reply.

`http_post/4` blocks until the model sends its whole reply. To show tokens as they arrive (streaming), you would read the reply with `http_open/3` in a loop, but most Prolog programs need the whole answer before they can reason over it.

{width: "80%"}
![Architecture diagram for the LLM Client example](FIG_llm_client.jpg)

The **llm_client** project provides clients for Google Gemini and Ollama. Here is the file **llm_client/prolog/gemini.pl**:

```prolog
%% gemini.pl - Google Gemini API client
:- module(gemini, [
    gemini_generate/2,
    gemini_generate/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).
:- use_module(library(option)).

%% gemini_generate(+Prompt, -Response)
%% Uses GOOGLE_API_KEY environment variable
gemini_generate(Prompt, Response) :-
    gemini_generate(Prompt, Response, []).

%% gemini_generate(+Prompt, -Response, +Options)
%% Options:
%%   model(Model)            default gemini-2.5-flash
%%   temperature(T)          sampling temperature
%%   max_output_tokens(N)    output length limit
%%   system(Text)            system instruction (persona, rules)
%%   json(true)              ask for a JSON reply (responseMimeType)
gemini_generate(Prompt, Response, Options) :-
    require_env('GOOGLE_API_KEY', ApiKey),
    option(model(Model), Options, 'gemini-2.5-flash'),
    format(atom(URL),
           'https://generativelanguage.googleapis.com/v1beta/models/~w:generateContent',
           [Model]),
    generation_config(Options, Config),
    Payload0 = _{ contents: [_{parts: [_{text: Prompt}]}],
                  generationConfig: Config },
    (   option(system(System), Options)
    ->  Payload = Payload0.put(systemInstruction,
                               _{parts: [_{text: System}]})
    ;   Payload = Payload0
    ),
    catch(
        http_post(URL, json(Payload), Result,
                  [request_header('x-goog-api-key'=ApiKey),
                   json_object(dict)]),
        E,
        (   log_llm_error(gemini, E),
            fail
        )),
    extract_text_response(Result, Response).

%% generation_config(+Options, -Config)
%% Build the generationConfig dict from the options that are present.
generation_config(Options, Config) :-
    foldl(config_entry(Options),
          [temperature-temperature, max_output_tokens-maxOutputTokens],
          _{}, Config0),
    (   option(json(true), Options)
    ->  Config = Config0.put(responseMimeType, "application/json")
    ;   Config = Config0
    ).

config_entry(Options, Opt-Key, C0, C) :-
    Term =.. [Opt, Value],
    (   option(Term, Options)
    ->  C = C0.put(Key, Value)
    ;   C = C0
    ).

%% require_env(+Name, -Value)
%% Get an environment variable or throw a clear existence_error.
require_env(Name, Value) :-
    (   getenv(Name, Value)
    ->  true
    ;   existence_error(env, Name)
    ).

%% extract_text_response(+Result, -Text)
%% Total: fails cleanly on error-shaped JSON (no candidates key).
extract_text_response(Result, Text) :-
    is_dict(Result),
    get_dict(candidates, Result, Candidates),
    Candidates = [First|_],
    is_dict(First),
    get_dict(content, First, Content),
    is_dict(Content),
    get_dict(parts, Content, Parts),
    Parts = [Part|_],
    is_dict(Part),
    get_dict(text, Part, Text).

log_llm_error(Backend, Error) :-
    print_message(warning, llm_error(Backend, Error)).

:- multifile prolog:message//1.

prolog:message(llm_error(Backend, Error)) -->
    ['llm_client/~w: request failed: ~w'-[Backend, Error]].
```

`gemini_generate/3` reads `GOOGLE_API_KEY`, builds the URL for the model, and posts the request with the key in the `x-goog-api-key` header (a key in the URL can end up in server logs). `option/3` from `library(option)` reads the options with defaults. `generation_config/2` adds `temperature` and `maxOutputTokens` to the `generationConfig` dict only when the caller gives them, and `json(true)` sets `responseMimeType` to `application/json`, which makes Gemini reply with JSON only. `system(Text)` adds a system instruction, which sets the model's role and rules for the whole request. `Dict.put(Key, Value)` returns a new dict with one more key; Prolog dicts never change in place.

`require_env/2` throws `existence_error(env, Name)` if the key is not set. `extract_text_response/2` follows the reply's `candidates[0].content.parts[0].text` path with `get_dict/3`, so an error reply makes it fail instead of throwing.

For models that run on your own machine, here is the main part of **llm_client/prolog/ollama.pl**:

```prolog
%% ollama.pl - Ollama local LLM API client
:- module(ollama, [
    ollama_generate/2,
    ollama_generate/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).

%% ollama_generate(+Prompt, -Response)
%% Uses default model and localhost:11434
ollama_generate(Prompt, Response) :-
    ollama_generate(Prompt, Response, [model('qwen3:1.7b')]).

%% ollama_generate(+Prompt, -Response, +Options)
ollama_generate(Prompt, Response, Options) :-
    (member(model(Model), Options) -> true ; Model = 'qwen3:1.7b'),
    URL = 'http://localhost:11434/api/generate',
    Payload = json([
        model=Model,
        prompt=Prompt,
        stream= @(false)
    ]),
    catch(
        http_post(URL, json(Payload), Result, [json_object(dict)]),
        E,
        (   log_ollama_error(E),
            fail
        )),
    (   is_dict(Result),
        get_dict(response, Result, Response)
    ->  true
    ;   log_ollama_error(unexpected_response(Result)),
        fail
    ).
```

The Ollama client calls the local Ollama server on port 11434. `stream= @(false)` asks for the whole reply in one JSON object; in the `json/1` notation, `@(false)` writes the JSON constant `false`. If the server is not running, the error message suggests `ollama serve`. The model defaults to `qwen3:1.7b`, a small model that runs on most laptops (install it with `ollama pull qwen3:1.7b`).

`make run` asks both models the same question. Your answers will differ, since LLM output varies from run to run:

```text
Gemini: Prolog is a declarative logic programming language where programs
consist of facts and rules, from which it infers answers to queries.
Ollama: Prolog is a logic programming language that uses rule-based
reasoning to solve problems and perform computations by manipulating
knowledge and constraints.
```

The options let you ask for structured replies:

```prolog
?- gemini_generate('Name one prime number below 10.', R,
       [json(true), temperature(0.0),
        system('Reply only with JSON of the form {"prime": N}.')]).
R = "{\"prime\": 7}".
```

## Structured Output from LLMs

Plain text suits people, but Prolog needs **structured data**. The technique is to ask the LLM for JSON with an exact schema. For example:

```
Extract all people and organizations from the following text.
Return your answer as JSON with this schema:
{"entities": [{"name": "...", "type": "person|org"}],
 "relations": [{"subject": "...", "predicate": "...", "object": "..."}]}
```

We parse the JSON into a dict and assert the entities and relations as Prolog facts. This connects the LLM's language understanding to Prolog's reasoning.

{width: "80%"}
![Architecture diagram for the Structured Output example](FIG_structured_output.jpg)

The **structured_output** project has two parts. Here is the first, **structured_output/prolog/json_to_facts.pl**, which turns JSON into facts:

```prolog
%% json_to_facts.pl - Convert structured LLM JSON output into Prolog
%% facts
:- module(json_to_facts, [
    json_string_to_facts/1,     % +JsonString
    json_string_to_facts/2,     % +JsonString, -Counts
    clear_extracted/0,          %
    extracted_entity/2,
    extracted_relation/3
]).

:- use_module(library(json)).

:- dynamic extracted_entity/2.    % extracted_entity(Name, Type)
:- dynamic extracted_relation/3.  % extracted_relation(Subject,
                                  %            Predicate, Object)

%% clear_extracted/0
%% Remove every asserted entity/relation fact (test setup helper).
clear_extracted :-
    retractall(extracted_entity(_, _)),
    retractall(extracted_relation(_, _, _)).

%% json_string_to_facts(+JsonString)
%% Parses JSON with entities/relations arrays into Prolog facts
json_string_to_facts(JsonString) :-
    json_string_to_facts(JsonString, _Counts).

%% json_string_to_facts(+JsonString, -Counts)
%% As /1 but also returns a counts dict:
%%   _{entities: NE, entities_with_warnings: WE,
%%     relations: NR, relations_with_warnings: WR}.
%% Malformed items are skipped with a print_message/2 warning and
%% counted, never thrown.
json_string_to_facts(JsonString, Counts) :-
    atom_json_dict(JsonString, Dict, []),
    (   get_dict(entities, Dict, Entities)
    ->  foldl(assert_entity, Entities, 0-0, NE-WE)
    ;   NE = 0, WE = 0
    ),
    (   get_dict(relations, Dict, Relations)
    ->  foldl(assert_relation, Relations, 0-0, NR-WR)
    ;   NR = 0, WR = 0
    ),
    Counts = _{ entities: NE, entities_with_warnings: WE,
                relations: NR, relations_with_warnings: WR }.

assert_entity(E, N0-W0, N-W) :-
    (   get_dict(name, E, Name), get_dict(type, E, Type)
    ->  (   \+ extracted_entity(Name, Type)
        ->  assertz(extracted_entity(Name, Type))
        ;   true
        ),
        N is N0 + 1, W = W0
    ;   print_message(warning,
            malformed_entity_skipped(E)),
        N = N0, W is W0 + 1
    ).

assert_relation(R, N0-W0, N-W) :-
    (   get_dict(subject, R, S),
        get_dict(predicate, R, P),
        get_dict(object, R, O)
    ->  (   \+ extracted_relation(S, P, O)
        ->  assertz(extracted_relation(S, P, O))
        ;   true
        ),
        N is N0 + 1, W = W0
    ;   print_message(warning,
            malformed_relation_skipped(R)),
        N = N0, W is W0 + 1
    ).
```

`json_string_to_facts/2` parses the JSON into a dict and uses `get_dict/3` to find the `entities` and `relations` arrays, either of which may be missing. LLMs sometimes leave out a field, so an item with a missing key is skipped with a warning, not an exception, and counted in the returned dict. `assert_entity/3` and `assert_relation/3` work with `foldl/4`, carrying a `Count-Warnings` pair. The duplicate check (`\+ extracted_entity(Name, Type)`) stops the same fact from being added twice when the LLM repeats itself.

After the call, the facts are ready to query:

```prolog
?- json_string_to_facts('{"entities":[{"name":"Paris","type":"city"}]}').
true.

?- extracted_entity(Name, Type).
Name = "Paris",
Type = "city".
```

JSON strings arrive as Prolog strings, so query them with double quotes: `extracted_entity("Paris", T)`.

The second part, **structured_output/prolog/llm_extract.pl**, asks Gemini to do the extraction:

```prolog
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
```

The prompt gives the exact schema and asks for predicates in one style, which makes the facts easier to query. `json(true)` makes Gemini reply with JSON only, and `temperature(0.0)` makes the reply as repeatable as the model allows. `make llm` runs it on one sentence:

```text
Extracted 3 entities and 3 relations
entity: Ada Lovelace (person)
entity: Charles Babbage (person)
entity: London (place)
relation: Ada Lovelace worked_with Charles Babbage
relation: Ada Lovelace worked_in London
relation: Charles Babbage worked_in London
```

Note `worked_in London`: the sentence says Ada Lovelace worked *with* Babbage *in* London, and the model turned that into two separate facts. This is a fair reading, but a model can also add facts the text does not support. The LLM Logic Guardrails chapter shows how Prolog rules can check LLM output before you trust it.

## Combining LLMs with Prolog Reasoning

A pattern that recurs in this book is the **hybrid AI pipeline**: a statistical model handles language (understanding, summarizing, extracting), and Prolog handles reasoning (rules, constraints, explanations).

A hybrid pipeline has four stages:
1. **Extraction**: An LLM or NLP model reads unstructured text and returns structured data (entities, relations, labels).
2. **Fact assertion**: The data becomes Prolog facts.
3. **Reasoning**: Prolog rules derive conclusions, classifications, or recommendations from the facts.
4. **Explanation**: Proof trees (see the Reasoning chapter) show *why* each conclusion holds, which an LLM cannot reliably do.

{width: "80%"}
![Architecture diagram for the Hybrid Pipeline example](FIG_hybrid_pipeline.jpg)

The **hybrid_pipeline** project builds this with spaCy, a Python NLP library, for entity extraction and Prolog for the rules, connected by the Janus bridge (covered in detail in the Janus chapter). Here is the file **hybrid_pipeline/prolog/pipeline.pl**:

```prolog
%% pipeline.pl - Hybrid AI pipeline: Python preprocessing + Prolog
%% reasoning
:- module(pipeline, [
    run_pipeline/2,
    ner_backend/1
]).

:- use_module(library(janus)).

:- dynamic extracted/2.

% Add the companion python/ directory to Python's module search path.
% prolog_load_context/2 gives this file's directory while it loads, so
% the module works from any current working directory.
:- prolog_load_context(directory, PrologDir),
   directory_file_path(PrologDir, '../python', PyDir),
   py_add_lib_dir(PyDir).

%% ner_backend(-Name)
%% Name is spacy when spaCy and its model loaded, else rules.
ner_backend(Name) :-
    py_call(nlp_bridge:backend(), Name).

%% run_pipeline(+InputText, -Result)
%% 1. Use Python/spaCy for NER extraction
%% 2. Assert extracted entities as Prolog facts
%% 3. Apply Prolog reasoning rules
%% 4. Return structured conclusions
run_pipeline(InputText, Result) :-
    setup_call_cleanup(
        true,
        (   %% Step 1: Python NER
            py_call(nlp_bridge:extract_entities(InputText), Entities),
            %% Step 2: Assert as Prolog facts
            maplist(assert_entity, Entities),
            %% Step 3: Prolog reasoning
            findall(conclusion(E, Type), entity_conclusion(E, Type),
                Conclusions),
            Result = pipeline_result(Entities, Conclusions)
        ),
        %% Cleanup: always retract, even on failure or exception
        retractall(extracted(_,_))).

%% extract_entities/1 returns a list of dicts:  _{text: T, label: L}
assert_entity(Entity) :-
    Text = Entity.text,
    Type = Entity.label,
    assertz(extracted(Text, Type)).

%% Only PERSON and GPE labels are mapped to conclusions; every other
%% spaCy entity label is deliberately dropped by these two clauses.
entity_conclusion(E, important_person) :-
    extracted(E, 'PERSON').
entity_conclusion(E, location) :-
    extracted(E, 'GPE').
```

`py_call/2` from `library(janus)` calls the Python function `extract_entities` in **python/nlp_bridge.py**, which runs spaCy and returns a list of Python dicts. Janus turns each into a Prolog dict, which prints as `py{...}`. `assert_entity/1` stores each as an `extracted/2` fact, and the `entity_conclusion/2` rules classify them. `setup_call_cleanup/3` removes the `extracted/2` facts afterward, even if a step fails.

The directive near the top adds the `python/` directory to Python's module search path. `prolog_load_context(directory, Dir)` gives the directory of the file being loaded, so the module works from any working directory.

`make run` sets up a Python environment with `uv` (it pins `spacy==3.8.11` and the `en_core_web_sm` model) and runs:

```text
NER backend: spacy
pipeline_result([py{label:'PERSON',text:'John Smith'},
                 py{label:'GPE',text:'London'},
                 py{label:'GPE',text:'Paris'},
                 py{label:'DATE',text:'last week'}],
                [conclusion('John Smith',important_person),
                 conclusion('London',location),
                 conclusion('Paris',location)])
```

spaCy found a date too, but no rule mentions `DATE`, so it yields no conclusion. If spaCy or its model is missing, `nlp_bridge.py` falls back to a few hard-coded names and `ner_backend/1` returns `rules`. The Janus chapter explains how the Makefile makes Janus and `uv` work together.

The pattern carries over to other parts: swap spaCy for an LLM call through `extract_facts/2`, and swap the two classification rules for an expert system's rules.

## Optional Practice Problems

1. **Historical Events**: Write a prompt for `structured_output` that asks for historical events in a text as JSON, and load the reply as `event(Name, Year, Location)` facts. Check that each `Year` is an integer before asserting it.
2. **Ollama Extraction**: Add a `backend(ollama)` option to `extract_facts/2`. Ollama's `/api/generate` accepts `"format": "json"`; compare the quality of `qwen3:1.7b` with Gemini on five sentences.
3. **Rules over Extracted Facts**: Write a rule `colleagues(A, B)` over `extracted_relation/3` that holds when the LLM reported `worked_with` in either direction, and test it on the output of `make llm`.
