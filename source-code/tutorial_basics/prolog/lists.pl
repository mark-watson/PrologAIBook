%% lists.pl - List processing examples
%% Demonstrates: head/tail, recursion, list predicates
%%
%% NOTE: this file is named lists.pl, but its module is `my_lists`.
%% Keeping the module name `my_lists` (rather than `lists`) is a
%% deliberate workaround: naming a module `lists` shadows SWI-Prolog's
%% own library(lists), which breaks library(plunit) and library(clpfd)
%% (they depend on library(lists) internally).  All public predicates
%% keep their original names and arities (my_length/2 etc.).

:- module(my_lists, [
    my_length/2,
    my_member/2,
    my_append/3,
    my_reverse/2,
    my_last/2
]).

:- use_module(library(clpfd)).

%% my_length(?List, ?N) - bidirectional length using CLP(FD)
%% Works in both directions: my_length([a,b,c], 3) succeeds, and
%% my_length(L, 3) binds L to a list of three fresh variables.
my_length(List, N) :-
    N #>= 0,
    my_length_(List, N).

my_length_([], 0).
my_length_([_|T], N) :-
    N #> 0,
    N1 #= N - 1,
    my_length_(T, N1).

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
