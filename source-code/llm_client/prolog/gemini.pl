%% gemini.pl - Google Gemini API client
:- module(gemini, [
    gemini_generate/2,
    gemini_generate/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).

%% gemini_generate(+Prompt, -Response)
%% Uses GOOGLE_API_KEY environment variable
gemini_generate(Prompt, Response) :-
    gemini_generate(Prompt, Response, []).

%% gemini_generate(+Prompt, -Response, +Options)
%% Options: model(Model), temperature(T), max_output_tokens(N)
gemini_generate(Prompt, Response, Options) :-
    require_env('GOOGLE_API_KEY', ApiKey),
    option_value(model, Options, Model, 'gemini-2.5-flash'),
    format(atom(URL),
           'https://generativelanguage.googleapis.com/v1beta/models/~w:generateContent',
           [Model]),
    option_value(temperature, Options, Temperature, none),
    option_value(max_output_tokens, Options, MaxTokens, none),
    Payload = _{
        contents: [_{parts: [_{text: Prompt}]}],
        generationConfig: Config
    },
    generation_config(Temperature, MaxTokens, ConfigPairs),
    (   ConfigPairs = []
    ->  Config = json([])
    ;   Config = json(ConfigPairs)
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

%% generation_config(+Temperature, +MaxTokens, -ConfigPairs)
%% Build the generationConfig pairs for the payload body.
generation_config(none, none, []).
generation_config(T, none, [temperature=T]) :- T \= none.
generation_config(none, Max, [maxOutputTokens=Max]) :- Max \= none.
generation_config(T, Max, [temperature=T, maxOutputTokens=Max]) :-
    T \= none, Max \= none.

%% require_env(+Name, -Value)
%% Get an environment variable or throw a clear existence_error.
require_env(Name, Value) :-
    (   getenv(Name, Value)
    ->  true
    ;   existence_error(env, Name)
    ).

%% option_value(+Key, +Options, -Value, +Default)
%% Simple member-based option lookup (library(option) not required).
option_value(Key, Options, Value, Default) :-
    Opt =.. [Key, Value],
    (   member(Opt, Options)
    ->  true
    ;   Value = Default
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
