# Natural Language Processing with Definite Clause Grammars

Definite Clause Grammars (DCGs) are one of Prolog's most powerful features for AI applications. DCGs allow us to write grammars directly as Prolog rules, making natural language processing and text parsing a natural fit for Prolog.

{width: "80%"}
![Architecture diagram for the DCG Parser example](FIG_dcg_parser.jpg)

{width: "80%"}
![Architecture diagram for the Text Analyzer example](FIG_text_analyzer.jpg)

## DCG Fundamentals

TBD: The `-->` notation, terminal and non-terminal symbols, and how DCGs desugar to difference lists. Building a simple English sentence parser.

## Tokenizing and Preprocessing Text

TBD: Splitting text into word lists, handling punctuation, normalizing case. Using SWI-Prolog's string and atom manipulation predicates.

The **dcg_parser** project includes a simple tokenizer that converts strings to word lists. Here is the file **dcg_parser/prolog/tokenizer.pl**:

```prolog
%% tokenizer.pl - Convert text strings into word lists for parsing
:- module(tokenizer, [tokenize/2]).

%% tokenize(+Text, -Words)
tokenize(Text, Words) :-
    atom_chars(Text, Chars),
    split_words(Chars, Words).

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
```

## Parsing Natural Language Sentences

TBD: Building a practical English grammar that handles noun phrases, verb phrases, prepositional phrases, and relative clauses. Extracting parse trees.

The **dcg_parser** project uses DCG notation to define an English grammar with parse tree construction. Here is the file **dcg_parser/prolog/english_grammar.pl**:

```prolog
%% english_grammar.pl - English grammar with parse tree construction
:- module(english_grammar, [parse_sentence/2]).

%% parse_sentence(+WordList, -ParseTree)
parse_sentence(Words, Tree) :-
    phrase(sentence(Tree), Words).

sentence(s(NP, VP)) --> noun_phrase(NP), verb_phrase(VP).

noun_phrase(np(det(D), n(N))) --> det(D), noun(N).
noun_phrase(np(name(N))) --> proper_noun(N).

verb_phrase(vp(v(V))) --> verb(V).
verb_phrase(vp(v(V), NP)) --> verb(V), noun_phrase(NP).
verb_phrase(vp(v(V), PP)) --> verb(V), prep_phrase(PP).
verb_phrase(vp(v(V), NP, PP)) --> verb(V), noun_phrase(NP),
                                  prep_phrase(PP).

prep_phrase(pp(p(P), NP)) --> prep(P), noun_phrase(NP).

%% Lexicon
det(the) --> [the].   det(a) --> [a].
noun(dog) --> [dog].   noun(cat) --> [cat].
noun(man) --> [man].   noun(park) --> [park].
verb(chases) --> [chases].  verb(runs) --> [runs].
verb(walks) --> [walks].    verb(sees) --> [sees].
prep(in) --> [in].    prep(on) --> [on].
proper_noun(john) --> [john].  proper_noun(mary) --> [mary].
```

## Semantic Analysis with DCGs

TBD: Augmenting DCG rules with semantic actions. Building meaning representations (logical forms) from parsed sentences.

## Named Entity Recognition

TBD: Detecting person names, place names, and organization names in text using Prolog pattern matching and gazetteer lookup tables.

The **text_analyzer** project implements NER with gazetteer lookup. Here is the file **text_analyzer/prolog/ner.pl**:

```prolog
%% ner.pl - Named Entity Recognition using gazetteer lookup
:- module(ner, [find_entities/2, person_name/1, place_name/1]).

%% Gazetteer data (expandable)
person_name('John').   person_name('Mary').
person_name('Smith').  person_name('Clinton').

place_name('London').  place_name('Paris').
place_name('USA').     place_name('England').

%% find_entities(+WordList, -Entities)
find_entities(Words, Entities) :-
    findall(entity(person, W),
        (member(W, Words), person_name(W)), People),
    findall(entity(place, W),
        (member(W, Words), place_name(W)), Places),
    append(People, Places, Entities).
```

## Text Categorization

TBD: A simple "bag of words" text categorizer implemented in Prolog, inspired by the approach from the author's Common Lisp NLP library.

The **text_analyzer** project includes a bag-of-words categorizer. Here is the file **text_analyzer/prolog/categorizer.pl**:

```prolog
%% categorizer.pl - Simple bag-of-words text categorization
:- module(categorizer, [categorize/2]).

category_words(politics,
    [president, congress, election, vote, senator]).
category_words(sports,
    [game, team, player, score, win, tournament]).
category_words(technology,
    [computer, software, algorithm, data, programming]).
category_words(economy,
    [market, stock, trade, bank, money, economy]).

%% categorize(+WordList, -Categories)
categorize(Words, Categories) :-
    findall(Score-Category,
        (   category_words(Category, Keywords),
            score_category(Words, Keywords, Score),
            Score > 0  ),
        Pairs),
    sort(1, @>=, Pairs, Categories).

score_category(Words, Keywords, Score) :-
    include(word_in_list(Keywords), Words, Matches),
    length(Matches, Score).

word_in_list(Keywords, Word) :-
    downcase_atom(Word, Lower),
    member(Lower, Keywords).
```

## Text Summarization

TBD: Extractive text summarization using sentence scoring based on category-relevant word weights.
