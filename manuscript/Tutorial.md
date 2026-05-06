# Prolog Tutorial

This chapter provides a hands-on introduction to Prolog for readers who are new to logic programming. We cover the essential concepts needed to understand the AI applications in later chapters.

{width: "80%"}
![Architecture diagram for the Tutorial Basics example](FIG_tutorial_basics.jpg)

## Facts, Rules, and Queries

TBD: Defining facts, writing rules, and querying the knowledge base. The fundamental Prolog data model.

The companion project **tutorial_basics** demonstrates core Prolog concepts with a family relationships knowledge base. Here is the file **tutorial_basics/prolog/family.pl**:

```prolog
%% family.pl - Facts, rules, and queries about family relationships
:- module(family, [
    parent/2,
    grandparent/2,
    sibling/2,
    ancestor/2
]).

%% Facts: parent(Parent, Child)
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).

%% Rules
grandparent(X, Z) :-
    parent(X, Y),
    parent(Y, Z).

sibling(X, Y) :-
    parent(Z, X),
    parent(Z, Y),
    X \= Y.

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :-
    parent(X, Z),
    ancestor(Z, Y).
```

## Unification and Pattern Matching

TBD: How Prolog's unification engine works. Variable binding, the occurs check, and practical examples.

## Backtracking and Search

TBD: Prolog's built-in depth-first search via backtracking. Cut (`!`), negation as failure (`\+`), and controlling the search.

## Lists and Recursive Data Structures

TBD: Head/tail notation (`[H|T]`), `member/2`, `append/3`, `length/2`, and writing recursive predicates.

The **tutorial_basics** project includes hand-rolled list utilities that mirror the built-in predicates. Here is the file **tutorial_basics/prolog/lists.pl**:

```prolog
%% lists.pl - List processing examples
:- module(my_lists, [
    my_length/2,
    my_member/2,
    my_append/3,
    my_reverse/2,
    my_last/2
]).

%% Length of a list
my_length([], 0).
my_length([_|T], N) :-
    my_length(T, N1),
    N is N1 + 1.

%% Membership
my_member(X, [X|_]).
my_member(X, [_|T]) :- my_member(X, T).

%% Append
my_append([], L, L).
my_append([H|T], L, [H|R]) :-
    my_append(T, L, R).

%% Reverse using accumulator
my_reverse(List, Reversed) :-
    my_reverse(List, [], Reversed).
my_reverse([], Acc, Acc).
my_reverse([H|T], Acc, Reversed) :-
    my_reverse(T, [H|Acc], Reversed).

%% Last element
my_last([X], X).
my_last([_|T], X) :- my_last(T, X).
```

## Arithmetic and Comparison

TBD: The `is/2` operator, comparison operators, and the difference between unification (`=`) and arithmetic evaluation.

## Input and Output

TBD: Reading and writing terms, reading files, and formatted output with `format/2`.

## Modules and Code Organization

TBD: Using `module/2` declarations, exporting predicates, and organizing larger Prolog programs across multiple files.

## Definite Clause Grammars (DCGs) — A First Look

TBD: Brief introduction to DCGs as syntactic sugar for difference lists. We will use DCGs extensively in the NLP chapter.

## Common SWI-Prolog Built-in Predicates

TBD: A reference table of the most useful built-in predicates: `findall/3`, `bagof/3`, `setof/3`, `assert/1`, `retract/1`, `functor/3`, `=../2` (univ), etc.
