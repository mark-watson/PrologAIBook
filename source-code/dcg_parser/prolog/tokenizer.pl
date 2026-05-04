%% tokenizer.pl - Simple text tokenizer for DCG input
:- module(tokenizer, [
    tokenize/2
]).

%% tokenize(+String, -Words)
%% Splits a string into a list of lowercase atoms
tokenize(String, Words) :-
    downcase_atom(String, Lower),
    atom_chars(Lower, Chars),
    split_words(Chars, Words).

split_words([], []).
split_words(Chars, [Word|Rest]) :-
    skip_spaces(Chars, Chars1),
    Chars1 \= [],
    take_word(Chars1, WordChars, Remaining),
    atom_chars(Word, WordChars),
    split_words(Remaining, Rest).
split_words(Chars, []) :-
    skip_spaces(Chars, []).

skip_spaces([' '|T], Rest) :- !, skip_spaces(T, Rest).
skip_spaces(L, L).

take_word([], [], []).
take_word([' '|T], [], T) :- !.
take_word([H|T], [H|W], Rest) :-
    H \= ' ',
    take_word(T, W, Rest).
