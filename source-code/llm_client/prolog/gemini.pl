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
%%   search(true)            let Gemini use Google Search (grounding)
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
    ->  Payload1 = Payload0.put(systemInstruction,
                                _{parts: [_{text: System}]})
    ;   Payload1 = Payload0
    ),
    (   option(search(true), Options)
    ->  Payload = Payload1.put(tools, [_{google_search: _{}}])
    ;   Payload = Payload1
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
%% Text joins the text of every part of the first candidate (a reply
%% that uses Google Search can come in several parts). Fails cleanly
%% on error-shaped JSON (no candidates key).
extract_text_response(Result, Text) :-
    is_dict(Result),
    get_dict(candidates, Result, Candidates),
    Candidates = [First|_],
    is_dict(First),
    get_dict(content, First, Content),
    is_dict(Content),
    get_dict(parts, Content, Parts),
    findall(T, ( member(Part, Parts),
                 is_dict(Part),
                 get_dict(text, Part, T) ),
            Texts),
    Texts \== [],
    atomic_list_concat(Texts, Text0),
    atom_string(Text0, Text).

log_llm_error(Backend, Error) :-
    print_message(warning, llm_error(Backend, Error)).

:- multifile prolog:message//1.

prolog:message(llm_error(Backend, Error)) -->
    ['llm_client/~w: request failed: ~w'-[Backend, Error]].
