:- module(test_grammar, []).
:- use_module(library(plunit)).
:- use_module('../prolog/english_grammar').

:- begin_tests(grammar).

test(simple_sentence) :-
    parse_sentence([the, dog, chases, the, cat], Tree),
    Tree = s(np(det(the), n(dog)), vp(v(chases), np(det(the), n(cat)))).

test(proper_noun_subject) :-
    parse_sentence([john, runs], Tree),
    Tree = s(np(name(john)), vp(v(runs))).

test(with_prep_phrase) :-
    parse_sentence([the, man, walks, in, the, park], _Tree).

test(invalid_sentence, [fail]) :-
    parse_sentence([the, the, the], _).

:- end_tests(grammar).
