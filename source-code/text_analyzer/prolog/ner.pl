%% ner.pl - Named Entity Recognition using expanded gazetteer lookup
:- module(ner, [
    find_entities/2,
    person_name/1,
    place_name/1,
    org_name/1
]).

%% Gazetteer — ~108 entries across person, place, and organization names
person_name('John').      person_name('Mary').      person_name('Smith').
person_name('Clinton').   person_name('Obama').     person_name('Trump').
person_name('Biden').     person_name('Harris').    person_name('Bush').
person_name('Reagan').    person_name('Kennedy').   person_name('Roosevelt').
person_name('Lincoln').   person_name('Jefferson'). person_name('Hamilton').
person_name('Franklin').  person_name('Churchill'). person_name('Thatcher').
person_name('Gandhi').    person_name('Mandela').   person_name('Einstein').
person_name('Newton').    person_name('Darwin').    person_name('Hemingway').
person_name('Austen').    person_name('Dickens').   person_name('Plato').
person_name('Aristotle'). person_name('Socrates').  person_name('Napoleon').
person_name('Caesar').    person_name('Columbus').  person_name('Gates').
person_name('Musk').      person_name('Turing').    person_name('President').

place_name('London').       place_name('Paris').        place_name('USA').
place_name('England').      place_name('Mexico').       place_name('Canada').
place_name('France').       place_name('Germany').      place_name('Italy').
place_name('Spain').        place_name('Japan').        place_name('China').
place_name('India').        place_name('Brazil').       place_name('Australia').
place_name('Russia').       place_name('Egypt').        place_name('Greece').
place_name('Turkey').       place_name('Sweden').       place_name('Norway').
place_name('Denmark').      place_name('Netherlands').  place_name('Switzerland').
place_name('Austria').      place_name('Portugal').     place_name('Poland').
place_name('Ukraine').      place_name('Korea').        place_name('Vietnam').
place_name('Thailand').     place_name('Nigeria').      place_name('Kenya').
place_name('South_Africa'). place_name('Argentina').    place_name('Colombia').
place_name('New_York').     place_name('California').   place_name('Texas').
place_name('Florida').      place_name('Berlin').       place_name('Rome').
place_name('Tokyo').        place_name('Beijing').      place_name('Moscow').
place_name('Sydney').       place_name('Cairo').        place_name('Dubai').
place_name('Singapore').    place_name('Hong_Kong').    place_name('Chicago').
place_name('Boston').       place_name('Seattle').      place_name('Toronto').
place_name('Barcelona').    place_name('Madrid').       place_name('Vienna').

org_name('United_Nations'). org_name('NATO').           org_name('European_Union').
org_name('Google').         org_name('Microsoft').      org_name('Apple').
org_name('Amazon').         org_name('NASA').           org_name('CIA').
org_name('FBI').            org_name('WHO').            org_name('UNESCO').
org_name('UNICEF').         org_name('Red_Cross').      org_name('Tesla').
org_name('SpaceX').         org_name('Meta').           org_name('Nike').
org_name('Samsung').        org_name('Toyota').

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
    findall(
        entity(org, W),
        (member(W, Words), org_name(W)),
        Orgs
    ),
    append(People, Places, Tmp),
    append(Tmp, Orgs, Entities).
