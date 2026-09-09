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

log_ollama_error(Error) :-
    print_message(warning, ollama_error(Error)).

:- multifile prolog:message//1.

%% Connection-refused style transport errors: hint at starting Ollama.
prolog:message(ollama_error(error(socket_error(econnrefused,_), _))) -->
    [ 'ollama: connection refused - is the Ollama server running?'-[],
      nl,
      '  Start it with: ollama serve'-[]
    ].
prolog:message(ollama_error(Error)) -->
    ['ollama: request failed: ~w'-[Error]].
