:- module(test_llm, []).
:- use_module(library(plunit)).
:- use_module('../prolog/gemini').
:- use_module('../prolog/ollama').

:- begin_tests(llm_client).

test(modules_load) :-
    true.  % API calls require keys/running Ollama; tested manually

:- end_tests(llm_client).
