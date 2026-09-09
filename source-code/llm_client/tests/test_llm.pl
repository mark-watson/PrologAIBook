:- module(test_llm, []).
:- use_module(library(plunit)).
:- use_module('../prolog/gemini').
:- use_module('../prolog/ollama').

:- begin_tests(llm_client).

%% Offline unit tests for extract_text_response/2 on canned dicts.

test(extract_text_response_success) :-
    Success = _{candidates: [
        _{content: _{parts: [_{text: "Hello from Gemini"}]}}
    ]},
    gemini:extract_text_response(Success, Text),
    assertion(Text == "Hello from Gemini").

test(extract_text_response_error_dict, [fail]) :-
    %% Error-shaped JSON (no candidates key) fails, does not throw.
    gemini:extract_text_response(_{error: _{message: "bad request"}}, _).

test(extract_text_response_empty_candidates, [fail]) :-
    gemini:extract_text_response(_{candidates: []}, _).

test(require_env_missing,
     [condition(\+ getenv('GOOGLE_API_KEY', _)),
      throws(error(existence_error(env, 'GOOGLE_API_KEY'), _))]) :-
    gemini:require_env('GOOGLE_API_KEY', _).

test(require_env_present,
     [condition(getenv('GOOGLE_API_KEY', _))]) :-
    gemini:require_env('GOOGLE_API_KEY', V),
    assertion(atom(V)).

:- end_tests(llm_client).
