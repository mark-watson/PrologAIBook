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
verb_phrase(vp(V, NP, PP)) --> verb(V), noun_phrase(NP), prep_phrase(PP).

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
