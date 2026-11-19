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
