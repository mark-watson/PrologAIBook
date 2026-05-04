%% ollama.pl - Ollama local LLM API client
:- module(ollama, [
    ollama_generate/2,
    ollama_generate/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json)).

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
        stream= @false
    ]),
    http_post(URL, json(Payload), Result, [json_object(dict)]),
    Response = Result.response.
