%% abduction.pl - Abductive reasoning with a meta-interpreter
:- module(abduction, [
    abduce/3,
    explanations/3
]).

%% abduce(+Goal, +Abducibles, -Explanation)
%% Explanation is a list of abducible goals that, if assumed true,
%% prove Goal. Backtracking yields other explanations. Goal is
%% module-sensitive, so rules are found in the caller's module.
:- meta_predicate abduce(:, +, -), explanations(:, +, -).

abduce(M:Goal, Abducibles, Expl) :-
    abduce(Goal, M, Abducibles, Expl).

abduce(true, _, _, []) :- !.
abduce((A, B), M, Abducibles, Expl) :- !,
    abduce(A, M, Abducibles, ExplA),
    abduce(B, M, Abducibles, ExplB),
    append(ExplA, ExplB, Expl).
abduce(Goal, _, Abducibles, [Goal]) :-
    memberchk(Goal, Abducibles).
abduce(Goal, M, Abducibles, Expl) :-
    \+ memberchk(Goal, Abducibles),
    clause(M:Goal, Body),
    abduce(Body, M, Abducibles, Expl).

%% explanations(+Goal, +Abducibles, -Sets)
%% Sets holds every distinct explanation, each sorted, smallest
%% first.
explanations(Goal, Abducibles, Sets) :-
    findall(Set,
            ( abduce(Goal, Abducibles, Expl), sort(Expl, Set) ),
            All),
    sort(All, Unique),
    map_list_to_pairs(length, Unique, Keyed),
    keysort(Keyed, Sorted),
    pairs_values(Sorted, Sets).

%% Example domain. The abducibles have no clauses: they are causes
%% we may assume, not facts we know. Load this file with
%% use_module/1 and query abduction:grass_is_wet, or copy these
%% rules into your own module.
:- dynamic rained/0, sprinkler_was_on/0, pipe_burst/0.

grass_is_wet :- rained.
grass_is_wet :- sprinkler_was_on.
street_is_wet :- rained.
street_is_wet :- pipe_burst.
