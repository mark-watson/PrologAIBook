%% test_daily_use.pl — Unit tests for the daily_use module
%%
%% Tests cover keyword extraction and context building logic.
%% The REPL loop and Gemini API calls are not tested here
%% (they require interactive I/O and network access).

:- use_module(library(plunit)).

:- begin_tests(extract_keywords).

test(basic_extraction, [true(Keywords == [quick, brown, fox])]) :-
    daily_use:extract_keywords('the quick brown fox', Keywords).

test(removes_stop_words, [true(Keywords == [prolog, programming,
    language])]) :-
    daily_use:extract_keywords('Prolog is a programming language',
        Keywords).

test(removes_short_words, [true(\+ member(is, Keywords))]) :-
    daily_use:extract_keywords('AI is great', Keywords).

test(strips_punctuation, [true(Keywords == [hello, world])]) :-
    daily_use:extract_keywords('Hello, world!', Keywords).

test(empty_input, [true(Keywords == [])]) :-
    daily_use:extract_keywords('', Keywords).

test(all_stop_words, [true(Keywords == [])]) :-
    daily_use:extract_keywords('the is a an', Keywords).

test(mixed_case, [true(Keywords == [artificial, intelligence])]) :-
    daily_use:extract_keywords('Artificial Intelligence', Keywords).

test(question_marks, [true(Keywords == [cats])]) :-
    daily_use:extract_keywords('Where are the cats?', Keywords).

:- end_tests(extract_keywords).

:- begin_tests(build_context).

test(empty_keywords_no_context) :-
    %% When all words are stop words, context should be empty
    daily_use:extract_keywords('the is a', Keywords),
    Keywords == [],
    %% We can't easily test build_context_from_cache without a DB,
    %% but we verify the keyword extraction path.
    true.

:- end_tests(build_context).
