# LLM Integration

Large Language Models are transforming AI, and Prolog can serve as a powerful orchestration layer — combining LLM-generated text with symbolic reasoning, structured knowledge, and explainable inference.

## Calling LLM APIs from Prolog

TBD: Making HTTP requests to LLM APIs. Handling API keys, rate limits, and streaming responses.

The **llm_client** project provides clients for Google Gemini and Ollama. Here is the file **llm_client/prolog/gemini.pl**:

```prolog
%% gemini.pl - Google Gemini API client
:- module(gemini, [gemini_generate/2, gemini_generate/3]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json)).

%% gemini_generate(+Prompt, -Response)
gemini_generate(Prompt, Response) :-
    gemini_generate(Prompt, Response, []).

%% gemini_generate(+Prompt, -Response, +Options)
gemini_generate(Prompt, Response, _Options) :-
    getenv('GOOGLE_API_KEY', ApiKey),
    format(atom(URL),
           'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=~w',
           [ApiKey]),
    Payload = json([
        contents=[json([
            parts=[json([text=Prompt])]
        ])]
    ]),
    http_post(URL, json(Payload), Result, [json_object(dict)]),
    extract_text_response(Result, Response).

extract_text_response(Result, Text) :-
    Candidates = Result.candidates,
    [First|_] = Candidates,
    Content = First.content,
    Parts = Content.parts,
    [Part|_] = Parts,
    Text = Part.text.
```

And a client for local Ollama models. Here is the file **llm_client/prolog/ollama.pl**:

```prolog
%% ollama.pl - Ollama API client for local LLMs
:- module(ollama, [ollama_generate/2, ollama_generate/3]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json)).

%% ollama_generate(+Prompt, -Response)
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
    http_post(URL, json(Payload), Result, [json_object(dict)]),
    Response = Result.response.
```

## Structured Output from LLMs

TBD: Prompting LLMs for JSON output and converting it to Prolog facts.

The **structured_output** project converts JSON LLM output into assertable Prolog facts. Here is the file **structured_output/prolog/json_to_facts.pl**:

```prolog
%% json_to_facts.pl - Convert structured LLM JSON output into Prolog facts
:- module(json_to_facts, [
    json_string_to_facts/1,
    extracted_entity/2,
    extracted_relation/3
]).

:- use_module(library(http/json)).

:- dynamic extracted_entity/2.
:- dynamic extracted_relation/3.

%% json_string_to_facts(+JsonString)
json_string_to_facts(JsonString) :-
    atom_json_dict(JsonString, Dict, []),
    (   get_dict(entities, Dict, Entities)
    ->  maplist(assert_entity, Entities)
    ;   true
    ),
    (   get_dict(relations, Dict, Relations)
    ->  maplist(assert_relation, Relations)
    ;   true
    ).

assert_entity(E) :-
    Name = E.name, Type = E.type,
    (   \+ extracted_entity(Name, Type)
    ->  assert(extracted_entity(Name, Type))
    ;   true
    ).

assert_relation(R) :-
    S = R.subject, P = R.predicate, O = R.object,
    (   \+ extracted_relation(S, P, O)
    ->  assert(extracted_relation(S, P, O))
    ;   true
    ).
```

## Combining LLMs with Prolog Reasoning

TBD: Using LLMs for natural language understanding and Prolog for structured reasoning. The best of both worlds.
