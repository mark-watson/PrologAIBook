%% tokenizer.pl - Text tokenizer for DCG input, written as a DCG
:- module(tokenizer, [
    tokenize/2
]).

%% tokenize(+Text, -Words)
%% Text is an atom or string. Words is a list of lowercase atoms.
%% Letters, digits, and apostrophes form words; everything else
%% (spaces, punctuation) separates them.
tokenize(Text, Words) :-
    string_lower(Text, Lower),
    string_codes(Lower, Codes),
    phrase(words(Words), Codes).

words([W|Ws]) -->
    separators,
    word_codes([C|Cs]),
    !,
    { atom_codes(W, [C|Cs]) },
    words(Ws).
words([]) -->
    separators.

separators --> [C], { \+ word_char(C) }, !, separators.
separators --> [].

word_codes([C|Cs]) --> [C], { word_char(C) }, !, word_codes(Cs).
word_codes([]) --> [].

word_char(C) :- code_type(C, alnum).
word_char(0'\').
