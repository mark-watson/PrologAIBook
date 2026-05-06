:- module(test_ner, []).
:- use_module(library(plunit)).
:- use_module('../prolog/ner').

:- begin_tests(ner).

test(find_person) :-
    find_entities(['John', walks, in, 'London'], Entities),
    memberchk(entity(person, 'John'), Entities).

test(find_place) :-
    find_entities(['John', walks, in, 'London'], Entities),
    memberchk(entity(place, 'London'), Entities).

test(find_org) :-
    find_entities(['Apple', released, new, software], Entities),
    memberchk(entity(org, 'Apple'), Entities).

test(find_all_types) :-
    find_entities(['Musk', visited, 'Tokyo', to, open, 'Tesla', office], Entities),
    memberchk(entity(person, 'Musk'), Entities),
    memberchk(entity(place, 'Tokyo'), Entities),
    memberchk(entity(org, 'Tesla'), Entities).

test(no_entities) :-
    find_entities([the, dog, runs], Entities),
    Entities == [].

test(historical_person) :-
    find_entities(['Churchill', gave, a, speech], Entities),
    memberchk(entity(person, 'Churchill'), Entities).

test(multiple_places) :-
    find_entities(['Paris', to, 'Berlin', via, 'Switzerland'], Entities),
    memberchk(entity(place, 'Paris'), Entities),
    memberchk(entity(place, 'Berlin'), Entities),
    memberchk(entity(place, 'Switzerland'), Entities).

test(international_body) :-
    find_entities(['UNESCO', and, 'WHO', collaborate], Entities),
    memberchk(entity(org, 'UNESCO'), Entities),
    memberchk(entity(org, 'WHO'), Entities).

:- end_tests(ner).