%% ner.pl - Named Entity Recognition using gazetteer lookup
:- module(ner, [
    find_entities/2,
    person_name/1,
    place_name/1
]).

%% Gazetteer data (expandable)
person_name('John').
person_name('Mary').
person_name('President').
person_name('Smith').
person_name('Clinton').

place_name('London').
place_name('Paris').
place_name('USA').
place_name('England').
place_name('Mexico').
place_name('Canada').

%% find_entities(+WordList, -Entities)
%% Returns entities as entity(Type, Name) terms
find_entities(Words, Entities) :-
    findall(
        entity(person, W),
        (member(W, Words), person_name(W)),
        People
    ),
    findall(
        entity(place, W),
        (member(W, Words), place_name(W)),
        Places
    ),
    append(People, Places, Entities).
