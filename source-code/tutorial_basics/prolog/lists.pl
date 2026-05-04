%% lists.pl - List processing examples
%% Demonstrates: head/tail, recursion, list predicates

:- module(lists, [
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
