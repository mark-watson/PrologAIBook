# Natural Language Processing with Definite Clause Grammars

Definite Clause Grammars (DCGs) let us write grammars directly as Prolog rules. In this chapter we use them to tokenize text, parse English sentences into trees, and translate sentences into logic. We also build simple tools for named entity recognition, text categorization, and summarization.

## DCG Fundamentals

A DCG describes a language, natural or formal, as a set of rules. Prolog compiles each rule into an ordinary clause, so you never write the list bookkeeping yourself.

#### The `-->` Notation
DCG rules use **`-->`** in place of `:-`.
- **Non-terminals** name syntactic categories (e.g., `sentence`, `noun_phrase`).
- **Terminals** are the words or tokens themselves, written as lists (e.g., `[the]`, `[dog]`).


{width: "90%"}
![Architecture diagram for the DCG Parser example](FIG_dcg_parser.jpg)

For example:
```prolog
sentence --> noun_phrase, verb_phrase.
```
This reads: "A sentence is a noun phrase followed by a verb phrase."

#### Translation to Difference Lists
Prolog compiles each DCG rule by adding two arguments to every non-terminal: the input list and the part of the list left after the rule has consumed its words. This pair is a **difference list**.

The rule `sentence --> noun_phrase, verb_phrase.` compiles into:
```prolog
sentence(InputList, RemainingList) :-
    noun_phrase(InputList, IntermediateList),
    verb_phrase(IntermediateList, RemainingList).
```

A terminal rule like `noun --> [dog].` compiles into a clause that matches the first word:
```prolog
noun([dog | Rest], Rest).
```

#### Parsing and Generating
Call a DCG with `phrase/2` or `phrase/3`. The **dcg_parser** project wraps its grammar in `parse_sentence(Words, Tree)`, which calls `phrase(sentence(Tree), Words)`.
- **Parsing** checks a list of words and builds a tree:
  ```prolog
  ?- parse_sentence([the, dog, runs], Tree).
  Tree = s(np(det(the), n(dog)), vp(v(runs))) .
  ```
- **Generating** leaves the words unbound, and Prolog produces sentences the grammar accepts:
  ```prolog
  ?- parse_sentence(Words, _).
  Words = [the, dog, sees] ;
  Words = [the, dog, chases] ;
  Words = [the, dog, walks] ;
  ...
  ```

## Tokenizing Text

Before a grammar can parse a sentence, we must turn the raw text into a list of tokens. **Tokenization** here means:
1. Converting the text to lowercase.
2. Dropping punctuation.
3. Splitting the text into words.

A DCG need not work on words. It can work on a list of character codes, which makes a DCG a good tool for writing the tokenizer itself. Here is the file **dcg_parser/prolog/tokenizer.pl**:

```prolog
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
```

`tokenize/2` lowercases the text with `string_lower/2`, turns it into a list of codes, and calls the `words//1` rule. (The notation `words//1` names a DCG rule with one visible argument.) `words//1` skips separators, reads one word, and recurses. The cut after `word_codes([C|Cs])` commits to the longest word, and the pattern `[C|Cs]` makes sure a word has at least one character. `0'\'` is the code for the apostrophe, so contractions such as *doesn't* stay whole.

```prolog
?- tokenize('The dog runs.', Words).
Words = [the, dog, runs].

?- tokenize("  John,  the man,   walks! ", Words).
Words = [john, the, man, walks].
```

## Parsing Sentences into Trees

To do more than accept or reject a sentence, we add arguments to the non-terminals. As the parse proceeds, the arguments unify to build a **parse tree**, a nested term that shows the structure of the sentence.

```prolog
sentence(s(NP, VP)) --> noun_phrase(NP), verb_phrase(VP).
```
If `noun_phrase` builds `np(det(the), n(dog))` and `verb_phrase` builds `vp(v(runs))`, the tree is `s(np(det(the), n(dog)), vp(v(runs)))`.

Here is the file **dcg_parser/prolog/english_grammar.pl**:

```prolog
%% english_grammar.pl - DCG-based English sentence parser
%% Parses simple English sentences and builds parse trees
:- module(english_grammar, [
    parse_sentence/2
]).

%% parse_sentence(+WordList, -ParseTree)
parse_sentence(Words, Tree) :-
    phrase(sentence(Tree), Words).

%% DCG Rules
sentence(s(NP, VP)) --> noun_phrase(NP), verb_phrase(VP).

noun_phrase(np(Det, N)) --> determiner(Det), noun(N).
noun_phrase(np(Name)) --> proper_noun(Name).

verb_phrase(vp(V)) --> verb(V).
verb_phrase(vp(V, NP)) --> verb(V), noun_phrase(NP).
verb_phrase(vp(V, PP)) --> verb(V), prep_phrase(PP).
verb_phrase(vp(V, NP, PP)) -->
    verb(V), noun_phrase(NP),
    prep_phrase(PP).

prep_phrase(pp(P, NP)) --> preposition(P), noun_phrase(NP).

%% Lexicon
determiner(det(the)) --> [the].
determiner(det(a)) --> [a].
determiner(det(an)) --> [an].

noun(n(dog)) --> [dog].
noun(n(cat)) --> [cat].
noun(n(park)) --> [park].
noun(n(ball)) --> [ball].
noun(n(man)) --> [man].
noun(n(woman)) --> [woman].

proper_noun(name(john)) --> [john].
proper_noun(name(mary)) --> [mary].

verb(v(sees)) --> [sees].
verb(v(chases)) --> [chases].
verb(v(walks)) --> [walks].
verb(v(likes)) --> [likes].
verb(v(runs)) --> [runs].

preposition(prep(in)) --> [in].
preposition(prep(to)) --> [to].
preposition(prep(with)) --> [with].
```

The four `verb_phrase` rules cover a verb alone, a verb with an object, a verb with a prepositional phrase, and a verb with both. Prolog tries them in order and backtracks when one fails:

```prolog
?- tokenize('The man walks in the park.', W), parse_sentence(W, T).
W = [the, man, walks, in, the, park],
T = s(np(det(the), n(man)),
      vp(v(walks), pp(prep(in), np(det(the), n(park))))) .
```

## From Sentences to Logic

A parse tree shows structure, but not meaning. We can also have a DCG build a **logic formula** for a sentence. The classic method, from Pereira and Warren's work on DCGs, passes partly built formulas between the rules.

Inside a DCG body, goals in curly braces `{ ... }` run as ordinary Prolog and consume no words. The file **dcg_parser/prolog/semantics.pl** uses them to look words up in a lexicon of plain facts:

```prolog
%% semantics.pl - Translate English sentences into logic formulas
%% and check them against a small world model.
:- module(semantics, [
    sentence_logic/2,
    holds/1,
    answer/2
]).

%% sentence_logic(+Words, -Formula)
sentence_logic(Words, Formula) :-
    phrase(sentence(Formula), Words).

%% A noun phrase gets the variable X that it describes and the
%% formula P1 for the rest of the sentence, and returns the full
%% formula P. A quantifier such as "every" wraps P1 inside P.
sentence(P) --> noun_phrase(X, P1, P), verb_phrase(X, P1).

noun_phrase(X, P1, P) --> determiner(X, P2, P1, P), noun(X, P2).
noun_phrase(X, P, P) --> proper_noun(X).

verb_phrase(X, P) --> trans_verb(X, Y, P1), noun_phrase(Y, P1, P).
verb_phrase(X, P) --> intrans_verb(X, P).

determiner(X, P1, P2, all(X, imp(P1, P2))) --> [every].
determiner(X, P1, P2, exists(X, and(P1, P2))) --> [a].

%% The lexicon is plain facts. The {...} goals look a word up and
%% build the predicate for it with =.. (univ).
noun(X, P) --> [W], { noun_word(W), P =.. [W, X] }.
proper_noun(W) --> [W], { name_word(W) }.
trans_verb(X, Y, P) --> [W], { trans_word(W, Pred), P =.. [Pred, X, Y] }.
intrans_verb(X, P) --> [W], { intrans_word(W, Pred), P =.. [Pred, X] }.

noun_word(dog).
noun_word(cat).
noun_word(person).

name_word(john).
name_word(mary).
name_word(rex).
name_word(tom).

trans_word(chases, chase).
trans_word(likes, like).
trans_word(owns, own).

intrans_word(runs, run).
intrans_word(sleeps, sleep).

%% World model used by holds/1.
dog(rex).
cat(tom).
person(john).
person(mary).
chase(rex, tom).
like(john, rex).
like(mary, rex).
like(mary, tom).
own(john, rex).
run(rex).
sleep(tom).

entity(X) :- member(X, [john, mary, rex, tom]).

%% holds(+Formula)
%% True when Formula is true in the world model. Quantifiers range
%% over the entities in entity/1.
holds(all(X, imp(P, Q))) :- !,
    forall((entity(X), holds(P)), holds(Q)).
holds(exists(X, and(P, Q))) :- !,
    entity(X), holds(P), holds(Q), !.
holds(Atom) :-
    call(Atom).

%% answer(+Words, -Answer)
%% Answer is yes or no for a sentence the grammar accepts.
answer(Words, Answer) :-
    once(sentence_logic(Words, Formula)),
    (   holds(Formula) -> Answer = yes ; Answer = no ).
```

The key idea is in the noun phrase rules. A noun phrase receives the variable `X` it describes and the formula `P1` that the rest of the sentence says about `X`, and it returns the full formula `P`. For "every dog", the determiner rule builds `P = all(X, imp(dog(X), P1))`. For a name such as "john", there is no quantifier, so `P` is just `P1` with `X = john`.

The lexicon rules show `{ ... }` at work. `noun(X, P) --> [W], { noun_word(W), P =.. [W, X] }.` reads one word, checks that it is a noun, and uses `=..` (univ) to build the term `dog(X)` from the atom `dog`. Adding a word now means adding one fact.

```prolog
?- sentence_logic([every, person, likes, a, dog], F).
F = all(_A, imp(person(_A), exists(_B, and(dog(_B), like(_A, _B))))) .
```

Because the formula is a Prolog term, we can check it against a world model. `holds/1` reads `all` with `forall/2` and `exists` by searching the entities:

```prolog
?- answer([every, person, likes, a, dog], A).
A = yes.

?- answer([every, person, owns, a, dog], A).
A = no.
```

Mary likes Rex, but only John owns him, so the second sentence is false. This is a tiny version of the natural language database interfaces built with Prolog since the 1970s. Mixing `{ ... }` goals into the grammar lets the same rules parse, build meaning, and query a database.

## Named Entity Recognition

{width: "80%"}
![Architecture diagram for the Text Analyzer example](FIG_text_analyzer.jpg)

Named Entity Recognition (NER) finds names in text and labels them as people, places, organizations, and so on.

A simple method uses a **gazetteer**: a list of known names. In Prolog the gazetteer is a set of facts such as `person_name('Einstein').`, and first-argument indexing makes lookups fast. The **text_analyzer** project holds 112 names. Here is the start of the gazetteer and the matching code from **text_analyzer/prolog/ner.pl**:

```prolog
:- module(ner, [
    find_entities/2,
    person_name/1,
    place_name/1,
    org_name/1
]).

person_name('John').
person_name('Mary').
person_name('Smith').
%% ... 32 more people ...

place_name('London').
place_name('Paris').
place_name('New_York').
%% ... 54 more places ...

org_name('United_Nations').
org_name('NASA').
%% ... 18 more organizations ...

%% find_entities(+WordList, -Entities)
%% Returns entity(Type, Name) terms in the order the names appear.
%% Words must keep their capital letters. A two-word name such as
%% ['New', 'York'] matches the gazetteer entry 'New_York'.
find_entities([], []).
find_entities([W1, W2|Ws], [entity(Type, Name)|Es]) :-
    atomic_list_concat([W1, W2], '_', Name),
    entity_type(Name, Type),
    !,
    find_entities(Ws, Es).
find_entities([W|Ws], [entity(Type, W)|Es]) :-
    entity_type(W, Type),
    !,
    find_entities(Ws, Es).
find_entities([_|Ws], Es) :-
    find_entities(Ws, Es).

entity_type(Name, person) :- person_name(Name).
entity_type(Name, place)  :- place_name(Name).
entity_type(Name, org)    :- org_name(Name).
```

`find_entities/2` walks the word list once. It first tries to join the next two words with an underscore, so `['New', 'York']` matches `'New_York'`. If that fails, it tries the single word, and if that fails too, it skips the word. The cuts commit to the first match, so each word belongs to at most one entity, and the entities come out in the order they appear:

```prolog
?- find_entities(['John', flew, from, 'New', 'York', to, 'London'], E).
E = [entity(person, 'John'), entity(place, 'New_York'),
     entity(place, 'London')].
```

The gazetteer is case-sensitive, so pass words with their original capital letters, not the lowercase output of `tokenize/2`. The Janus and LLM chapters show NER methods that handle names not in any list.

## Text Categorization

Text categorization assigns labels to a document based on its words. A simple method is **bag-of-words scoring**: ignore grammar and word order, and count how many words match each category's keyword list.

The file **text_analyzer/prolog/categorizer.pl** defines eight categories with 40 keywords each, such as:

```prolog
category_words(economy, [
    market, stock, trade, bank, money, economy, financial, tax, debt,
    inflation, interest_rate, revenue, investment, shareholder, bond,
    %% ... 25 more keywords ...
]).
```

Here is the scoring code from the same file:

```prolog
%% categorize(+WordList, -Categories)
%% Returns Score-Category pairs for every category with a score
%% above zero, highest score first.
categorize(Words, Categories) :-
    findall(
        Score-Category,
        (   category_words(Category, Keywords),
            keyword_count(Words, Keywords, Score),
            Score > 0
        ),
        Pairs
    ),
    sort(1, @>=, Pairs, Categories).

%% keyword_count(+Words, +Keywords, -Count)
%% Count the words and adjacent word pairs that match a keyword.
keyword_count(Words, Keywords, Count) :-
    maplist(downcase_atom, Words, Lower),
    bigrams(Lower, Pairs),
    append(Lower, Pairs, Terms),
    include(keyword_match(Keywords), Terms, Matches),
    length(Matches, Count).

%% bigrams(+Words, -Joined): [interest, rate] gives [interest_rate].
bigrams([W1, W2|Ws], [B|Bs]) :-
    !,
    atomic_list_concat([W1, W2], '_', B),
    bigrams([W2|Ws], Bs).
bigrams(_, []).

%% keyword_match(+Keywords, +Term)
%% Term is a keyword, or a plural ending in s whose singular is.
keyword_match(Keywords, Term) :-
    (   memberchk(Term, Keywords)
    ->  true
    ;   atom_concat(Singular, s, Term),
        memberchk(Singular, Keywords)
    ).
```

`keyword_count/3` does three things before counting. It lowercases the words, adds every pair of adjacent words joined by an underscore (so `[interest, rate]` can match `interest_rate`), and accepts a plural ending in *s* when the singular is a keyword. `sort(1, @>=, Pairs, Categories)` sorts on the score, highest first, and keeps pairs with equal scores in the order the categories are defined.

```prolog
?- categorize([president, election, vote, market], Categories).
Categories = [3-politics, 1-economy].
```

## Text Summarization

Extractive summarization picks the sentences from a document that best represent it. With our keyword lists, we can:
1. Score each sentence by how many keywords of a category it contains.
2. Sort the sentences by score.
3. Keep the top few.

Here is the file **text_analyzer/prolog/summarizer.pl**, which reuses `keyword_count/3`:

```prolog
%% summarizer.pl - Extractive summarization with category keywords
:- module(summarizer, [
    summarize/3,
    summarize/4
]).

:- use_module(categorizer, [category_words/2, keyword_count/3]).

%% summarize(+Sentences, +Category, -Summary)
%% Summary holds the two sentences that best match Category.
summarize(Sentences, Category, Summary) :-
    summarize(Sentences, Category, 2, Summary).

%% summarize(+Sentences, +Category, +N, -Summary)
%% Sentences is a list of word lists. Summary holds up to N of them,
%% highest keyword count first. Sentences with no matches are left
%% out. Ties keep their order in the input.
summarize(Sentences, Category, N, Summary) :-
    category_words(Category, Keywords),
    findall(Score-S,
            (   member(S, Sentences),
                keyword_count(S, Keywords, Score),
                Score > 0
            ),
            Scored),
    sort(1, @>=, Scored, Sorted),
    length(Sorted, Len),
    Take is min(N, Len),
    length(Top, Take),
    append(Top, _, Sorted),
    pairs_values(Top, Summary).
```

`length(Top, Take)` makes a list of `Take` fresh variables, and `append(Top, _, Sorted)` binds them to the first `Take` pairs of `Sorted`. This is a common Prolog idiom for taking a list prefix.

### Running the Summarizer

Here we summarize three sentences for the technology category:

```prolog
?- Sentences = [
       [the, hospital, installed, a, new, software, database, system],
       [technology, startups, are, building, quantum, encryption,
        algorithms],
       [cats, and, dogs, run, in, the, local, park]
   ],
   summarize(Sentences, technology, Summary).
Summary = [
   [technology, startups, are, building, quantum, encryption,
    algorithms],
   [the, hospital, installed, a, new, software, database, system]
].
```

The second sentence scores 4 (*startups*, *quantum*, *encryption*, *algorithms*) and the first scores 2 (*software*, *database*). The third matches no keywords, so it is left out.

## Optional Practice Problems

1. **Adjectives**: Extend `english_grammar.pl` so a noun phrase can hold any number of adjectives (e.g., "the quick brown dog runs"). Add an `adjectives//1` rule that returns a list, and include the list in the `np` tree.
2. **Questions**: Extend `semantics.pl` to accept questions such as "who likes rex" and "does john own a dog". Translate "who" into a variable, and make `answer/2` return the matching names.
3. **NER from Raw Text**: Write `text_entities(+Text, -Entities)` in `text_analyzer` that splits raw text into words while keeping capital letters (hint: `split_string/4`), then calls `find_entities/2`.
