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
