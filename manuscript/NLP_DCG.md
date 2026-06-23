# Natural Language Processing with Definite Clause Grammars

Definite Clause Grammars (DCGs) are one of Prolog's most powerful features for AI applications. DCGs allow us to write grammars directly as Prolog rules, making natural language processing and text parsing a natural fit for Prolog.

## DCG Fundamentals

Definite Clause Grammars (DCGs) are a formal way of describing languages (both natural languages and programming languages) in Prolog. Under the hood, they compile directly into standard Prolog clauses, eliminating the need to write complex list manipulation code manually.

#### The `-->` Notation
In standard Prolog rules, the neck operator is `:-`. In DCGs, rules are defined using the grammar rule pointer **`-->`**.
- **Non-terminal symbols**: Represent syntactic categories (e.g., `sentence`, `noun_phrase`).
- **Terminal symbols**: Represent the actual words or tokens in the language, written as list literals (e.g., `[the]`, `[dog]`).


{width: "90%"}
![Architecture diagram for the DCG Parser example](FIG_dcg_parser.jpg)

For example, a simple grammar rule:
```prolog
sentence --> noun_phrase, verb_phrase.
```
This states: "A sentence consists of a noun phrase followed by a verb phrase."

#### Desugaring to Difference Lists
When Prolog compiles a DCG rule, it appends two hidden variables representing a **difference list** to each non-terminal. A difference list is a pair of lists representing a prefix: the input list and what remains after the predicate has consumed its part.

For example, the rule `sentence --> noun_phrase, verb_phrase.` compiles into:
```prolog
sentence(InputList, RemainingList) :-
    noun_phrase(InputList, IntermediateList),
    verb_phrase(IntermediateList, RemainingList).
```

Terminal rules like `noun --> [dog].` compile into simple unifications:
```prolog
noun([dog | Rest], Rest).
```

#### Parsing and Generating
To call a DCG predicate, use the built-in `phrase/2` or `phrase/3` helper.
- **Parsing** (validating input):
  ```prolog
  ?- phrase(sentence, [the, dog, runs]).
  true.
  ```
- **Generating** (producing sentences from the grammar):
  ```prolog
  ?- phrase(sentence, Words).
  Words = [the, dog, chases, the, dog] ;
  Words = [the, dog, chases, the, cat] ;
  ...
  ```

## Tokenizing and Preprocessing Text

Before a grammar can parse a natural language sentence, the raw input string must be converted into a list of clean tokens. This process, called **tokenization**, involves:
1. Normalizing the character casing (converting everything to lowercase).
2. Handling and stripping punctuation.
3. Splitting the stream of characters on spaces to form separate atoms.

In SWI-Prolog, this can be done using built-in predicates like `downcase_atom/2` (which normalizes case) and `atom_chars/2` (which decomposes an atom into a list of characters).

{width: "80%"}
![Architecture diagram for the Text Analyzer example](FIG_text_analyzer.jpg)

The **dcg_parser** project includes a simple tokenizer that converts strings to word lists. Here is the file **dcg_parser/prolog/tokenizer.pl**:

```prolog
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
```

## Parsing Natural Language Sentences

To analyze a sentence beyond simple validation, we can augment DCG rules to construct a **parse tree**. This is done by adding arguments to our non-terminals. During the parsing process, these arguments unify to construct a nested Prolog compound term representing the syntactic structure of the sentence.

For example, we can define the non-terminals with arguments:
```prolog
sentence(s(NP, VP)) --> noun_phrase(NP), verb_phrase(VP).
```
If `noun_phrase` unifies with `np(det(the), n(dog))` and `verb_phrase` unifies with `vp(v(runs))`, the resulting tree will be `s(np(det(the), n(dog)), vp(v(runs)))`.

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

Beyond syntactic parsing, we can use DCGs to extract the **semantic meaning** of sentences. By inserting arbitrary Prolog goals inside curly braces `{ ... }`, we can execute code during the parse. These are called **semantic actions**.

One common application is constructing logical formulas or query representations directly from the syntax tree. For example, we can map a sentence like "every person likes a cat" into a first-order logic representation:

```prolog
sentence(every(X, Type => Likes)) --> noun_phrase(X, Type), verb_phrase(X, Likes).

noun_phrase(X, person) --> [everyone].
noun_phrase(X, person) --> [every, person].

verb_phrase(X, likes(X, Y)) --> [likes], noun_phrase(Y, _).
```

Running this grammar:
```prolog
?- phrase(sentence(Semantics), [every, person, likes, everyone]).
Semantics = every(_A, person=>likes(_A, _B)).
```

By passing semantic variables up the parse tree and executing constraints inside `{ ... }`, DCGs can translate natural language questions directly into database queries or logical structures.

## Named Entity Recognition

Named Entity Recognition (NER) is an information extraction task that identifies and classifies key entities in text into predefined categories such as person names, geographic locations, and organizations.

In Prolog, this can be efficiently implemented using a **gazetteer**—a lookup database of known names. By asserting these names as facts (e.g., `person_name('Einstein').`), we can use Prolog's high-speed indexing and pattern matching to scan tokenized word lists and extract typed entity structures.

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

Text categorization involves assigning predefined labels to a document based on its textual content. A classic, lightweight approach is **bag-of-words scoring**. In this approach, we ignore grammar and word order, and instead match words against category-specific keyword lists.

In Prolog, we can define keywords for different categories (e.g., politics, technology, economy) and score an input document by counting the overlaps.

The **text_analyzer** project includes a bag-of-words categorizer. Here is the file **text_analyzer/prolog/categorizer.pl**:

```prolog
%% categorizer.pl - Bag-of-words text categorization with expanded vocabulary
:- module(categorizer, [
    categorize/2
]).

%% categorize(+WordList, -Categories)
%% Returns list of category-score pairs, sorted by score descending
categorize(Words, Categories) :-
    findall(
        Score-Category,
        (   category_words(Category, Keywords),
            score_category(Words, Keywords, Score),
            Score > 0
        ),
        Pairs
    ),
    sort(1, @>=, Pairs, Categories).

score_category(Words, Keywords, Score) :-
    include(word_in_list(Keywords), Words, Matches),
    length(Matches, Score).

word_in_list(Keywords, Word) :-
    downcase_atom(Word, Lower),
    member(Lower, Keywords).
```

## Text Summarization

Extractive text summarization is the process of selecting a subset of sentences from a larger document that best represent its overall meaning or core categories. In a logic programming paradigm, this can be implemented by:
1. Scoring each sentence based on the count or weights of category-specific keywords it contains.
2. Ranking sentences by their score.
3. Selecting the top-ranked sentences to form the summary.

Here is a simple, elegant implementation of an extractive summarizer that scores sentences using keywords from our categorization system:

```prolog
:- module(summarizer, [summarize/3]).
:- use_module(categorizer, [category_words/2]).

%% summarize(+Sentences, +Category, -Summary)
%% Extracts the top 2 sentences representing the given Category
summarize(Sentences, Category, Summary) :-
    category_words(Category, Keywords),
    score_sentences(Sentences, Keywords, ScoredSentences),
    % Sort by score descending (keysort sorts ascending, so we negate/reverse)
    sort(1, @>=, ScoredSentences, Sorted),
    % Take the top 2 sentences
    take(2, Sorted, TopScored),
    % Extract the sentences from the score-sentence pairs
    pairs_values(TopScored, Summary).

score_sentences([], _, []).
score_sentences([S|Rest], Keywords, [Score-S | ScoredRest]) :-
    score_sentence(S, Keywords, Score),
    score_sentences(Rest, Keywords, ScoredRest).

score_sentence(Sentence, Keywords, Score) :-
    include(word_in_keywords(Keywords), Sentence, Matches),
    length(Matches, Score).

word_in_keywords(Keywords, Word) :-
    downcase_atom(Word, Lower),
    member(Lower, Keywords).

take(0, _, []) :- !.
take(_, [], []) :- !.
take(N, [X|Xs], [X|Ys]) :-
    N > 0,
    N1 is N - 1,
    take(N1, Xs, Ys).
```

### Running the Summarizer

To summarize a short text with three sentences about technology and healthcare:

```prolog
?- Sentences = [
       [the, hospital, installed, a, new, software, database, system],
       [technology, startups, are, building, quantum, encryption, algorithms],
       [cats, and, dogs, run, in, the, local, park]
   ],
   summarize(Sentences, technology, Summary).
Summary = [
   [technology, startups, are, building, quantum, encryption, algorithms],
   [the, hospital, installed, a, new, software, database, system]
].
```

## Optional Practice Problems

1. **Adjective Support**: Modify the DCG parser in the `dcg_parser` project to support adjectives modifying nouns (e.g., parsing sentences like "the quick brown fox jumps"). Update your grammar rules to handle arbitrary numbers of adjectives.
2. **Question Answering Rule**: In `text_analyzer`, add categorizer rules to recognize question patterns (e.g., sentences starting with interrogatives like "who", "what", "where") and extract the question target.
