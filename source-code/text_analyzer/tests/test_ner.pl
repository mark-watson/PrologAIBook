:- module(test_ner, []).
:- use_module(library(plunit)).
:- use_module('../prolog/ner').

:- begin_tests(ner).

test(find_person) :-
    find_entities(['John', walks, in, 'London'], Entities),
    member(entity(person, 'John'), Entities).

test(find_place) :-
    find_entities(['John', walks, in, 'London'], Entities),
    member(entity(place, 'London'), Entities).

test(no_entities) :-
    find_entities([the, dog, runs], Entities),
    Entities == [].

:- end_tests(ner).
