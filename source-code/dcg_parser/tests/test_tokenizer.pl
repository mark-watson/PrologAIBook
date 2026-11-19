:- module(test_tokenizer, []).
:- use_module(library(plunit)).
:- use_module('../prolog/tokenizer').

:- begin_tests(tokenizer).

test(lowercases_and_strips_punctuation) :-
    tokenize('The dog runs.', Words),
    assertion(Words == [the, dog, runs]).

test(extra_spaces_and_commas) :-
    tokenize("  John,  the man,   walks! ", Words),
    assertion(Words == [john, the, man, walks]).

test(keeps_apostrophes) :-
    tokenize("Mary doesn't run", Words),
    assertion(Words == [mary, 'doesn\'t', run]).

test(empty_text) :-
    tokenize('', Words),
    assertion(Words == []).

:- end_tests(tokenizer).
