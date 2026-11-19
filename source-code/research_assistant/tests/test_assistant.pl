:- module(test_assistant, []).
:- use_module(library(plunit)).
:- use_module('../prolog/assistant').

% These tests need no network. `make run` exercises the live pipeline.

:- begin_tests(assistant, [cleanup(clear_knowledge)]).

test(search_terms_drop_question_words) :-
    search_terms("What is the Warren Abstract Machine?", Q),
    assertion(Q == 'Warren Abstract Machine').

test(search_terms_keep_names) :-
    search_terms("Who was Alain Colmerauer?", Q),
    assertion(Q == 'Alain Colmerauer').

test(numbered_sources) :-
    assistant:numbered_sources(['A'-"Text a"-'http://a', 'B'-"Text b"-'http://b'],
                               1, Src, Refs),
    assertion(Src == "[1] A: Text a\n[2] B: Text b\n"),
    assertion(Refs == "[1] http://a\n[2] http://b\n").

test(known_page_not_fetched_again) :-
    clear_knowledge,
    assertz(assistant:knowledge('Prolog', "A logic language.", 'http://x')),
    % ensure_knowledge/1 must succeed from the stored fact alone,
    % without any network access.
    assistant:ensure_knowledge('Prolog'),
    aggregate_all(count, knowledge('Prolog', _, _), N),
    assertion(N == 1).

:- end_tests(assistant).
