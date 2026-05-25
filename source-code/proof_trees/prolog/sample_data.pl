%% sample_data.pl - Extended sample data for proof tree examples
%%
%% A multi-generational family tree providing
%% diverse proof tree scenarios:
%%   - Direct facts (parent/2)
%%   - Conjunctions (grandparent/2, sibling/2)
%%   - Recursion (ancestor/2)
%%   - Multi-step derivations (great_grandparent/2, descendant/2)
%%   - Negation-as-failure (sibling/2 via \=)
%%   - Multiple clauses per predicate

%% --- Direct facts: parent/2 -------------------------
%% Generation 1: great-grandparents
parent(adam,   john).
parent(eve,    john).
parent(adam,   robert).
parent(eve,    robert).

%% Generation 2: grandparents
parent(john,   mary).
parent(sarah,  mary).
parent(john,   michael).
parent(sarah,  michael).
parent(robert, susan).
parent(diana,  susan).

%% Generation 3: parents
parent(mary,     ann).
parent(tom,      ann).
parent(mary,     bob).
parent(tom,      bob).
parent(michael,  james).
parent(laura,    james).
parent(michael,  linda).
parent(laura,    linda).
parent(susan,    kate).
parent(peter,    kate).
parent(susan,    leo).
parent(peter,    leo).

%% Generation 4: children
parent(ann,    carol).
parent(jim,    carol).
parent(ann,    david).
parent(jim,    david).
parent(bob,    emma).
parent(lisa,   emma).
parent(bob,    frank).
parent(lisa,   frank).

%% Generation 5: grandchildren
parent(carol,  grace).
parent(david,  henry).

%% --- Rules ----------------------------------------

%% grandparent(X, Z) - X is a grandparent of Z (conjunction)
grandparent(X, Z) :-
    parent(X, Y),
    parent(Y, Z).

%% great_grandparent(X, Z) - X is a great-grandparent of Z (multi-step)
great_grandparent(X, Z) :-
    grandparent(X, Y),
    parent(Y, Z).

%% ancestor(X, Z) - X is an ancestor of Z (recursive, two clauses)
ancestor(X, Z) :-
    parent(X, Z).
ancestor(X, Z) :-
    parent(X, Y),
    ancestor(Y, Z).

%% descendant(X, Y) - X is a descendant of Y (uses ancestor)
descendant(X, Y) :-
    ancestor(Y, X).

%% sibling(X, Y) - X and Y share a parent (conjunction + negation)
sibling(X, Y) :-
    parent(P, X),
    parent(P, Y),
    X \= Y.

%% cousin(X, Y) - X and Y share a grandparent (conjunction)
cousin(X, Y) :-
    grandparent(GP, X),
    grandparent(GP, Y),
    X \= Y,
    \+ sibling(X, Y).

%% aunt_uncle(X, Y) - X is an aunt or uncle of Y
aunt_uncle(X, Y) :-
    parent(P, Y),
    sibling(X, P).