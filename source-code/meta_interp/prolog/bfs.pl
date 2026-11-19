%% bfs.pl - Breadth-first meta-interpreter
%%
%% Prolog searches depth first, so a left-recursive rule such as
%%   path(X, Y) :- path(X, Z), edge(Z, Y).
%% loops forever. A breadth-first interpreter explores all proofs of
%% one length before any longer proof, so it finds every answer that
%% has a proof, and the shortest proofs first.
:- module(bfs, [
    mi_bfs/2,
    mi_bfs/3
]).

%% mi_bfs(+Goal, +MaxStates)
%% mi_bfs(+Module, +Goal, +MaxStates)
%% Solve Goal breadth first. Each search state is a pair
%% Answer-Resolvent: a copy of Goal and the list of goals still to
%% prove. findall/3 copies states, so each keeps its own bindings, and
%% Answer shows how that branch has instantiated Goal. On
%% backtracking, mi_bfs/3 returns further answers. It gives up after
%% expanding MaxStates states, since a goal with no proof would
%% otherwise run forever.
mi_bfs(Goal, MaxStates) :-
    mi_bfs(user, Goal, MaxStates).

mi_bfs(Mod, Goal, MaxStates) :-
    bfs([Goal-[Goal]], Mod, Goal, MaxStates).

bfs([Answer-[]|Queue], Mod, Goal, Max) :- !,
    (   Goal = Answer
    ;   bfs(Queue, Mod, Goal, Max)
    ).
bfs([State|Queue], Mod, Goal, Max) :-
    Max > 0,
    expand(State, Mod, Children),
    append(Queue, Children, Queue1),
    Max1 is Max - 1,
    bfs(Queue1, Mod, Goal, Max1).

%% expand(+State, +Module, -Children)
%% The states reached by one step on the first goal of the resolvent.
expand(Answer-[true|Gs], _, [Answer-Gs]) :- !.
expand(Answer-[(A, B)|Gs], _, [Answer-[A, B|Gs]]) :- !.
expand(Answer-[G|Gs], Mod, Children) :-
    predicate_property(Mod:G, built_in), !,
    findall(Answer-Gs, call(Mod:G), Children).
expand(Answer-[G|Gs], Mod, Children) :-
    findall(Answer-[Body|Gs], clause(Mod:G, Body), Children).
