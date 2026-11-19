%% blocks.pl - Blocks World planner
:- module(blocks, [
    blocks_plan/3,
    blocks_plan_dfs/3,
    print_state/1
]).

:- use_module(library(lists), [subset/2]).

%% blocks_plan(+InitState, +GoalState, -Moves)
%% Breadth-first search, so Moves is a shortest plan. State is a list
%% of on(X,Y) and on_table(X) atoms; clear/2 is derived, not stored.
%% The queue holds Moves-State pairs with the moves in reverse order.
%% Seen holds every state already queued, sorted so that the same
%% state in a different order is recognized.
blocks_plan(State, Goal, Moves) :-
    sort(State, Key),
    bfs([[]-State], Goal, [Key], RevMoves),
    reverse(RevMoves, Moves).

bfs([RevMoves-State|_], Goal, _, RevMoves) :-
    subset(Goal, State), !.
bfs([RevMoves-State|Queue], Goal, Seen, Plan) :-
    findall([Move|RevMoves]-New, blocks_move(State, Move, New), Children),
    new_states(Children, Seen, Fresh, Seen1),
    append(Queue, Fresh, Queue1),
    bfs(Queue1, Goal, Seen1, Plan).

new_states([], Seen, [], Seen).
new_states([Ms-S|Rest], Seen, Fresh, Seen1) :-
    sort(S, Key),
    (   memberchk(Key, Seen)
    ->  Fresh = Fresh1, Seen2 = Seen
    ;   Fresh = [Ms-S|Fresh1], Seen2 = [Key|Seen]
    ),
    new_states(Rest, Seen2, Fresh1, Seen1).

%% blocks_plan_dfs(+InitState, +GoalState, -Moves)
%% Depth-first search with a list of visited states. It finds a plan
%% quickly but often a long one; compare it with blocks_plan/3.
blocks_plan_dfs(State, Goal, Moves) :-
    sort(State, Key),
    dfs(State, Goal, [Key], Moves).

dfs(State, Goal, _, []) :-
    subset(Goal, State), !.
dfs(State, Goal, Visited, [Move|Moves]) :-
    blocks_move(State, Move, New),
    sort(New, Key),
    \+ memberchk(Key, Visited),
    dfs(New, Goal, [Key|Visited], Moves).

%% blocks_move(+State, -Move, -NewState)
%% Moving a block X onto block To is the same whether X starts on
%% the table or on another block; only the source fact differs.
%% This shared rule merges the old duplicated clause pair.
blocks_move(State, move(X, From, To), NewState) :-
    from_fact(State, X, From, FromFact),
    clear(X, State),
    block_in_state(To, State),
    dif(X, To),
    clear(To, State),
    select(FromFact, State, S1),
    NewState = [on(X, To)|S1].
blocks_move(State, move_to_table(X, From), NewState) :-
    member(on(X, From), State),
    clear(X, State),
    select(on(X, From), State, S1),
    NewState = [on_table(X)|S1].

%% from_fact(+State, +X, -From, -Fact)
%% Where X currently sits: on the table, or on another block.
from_fact(State, X, table, on_table(X)) :- member(on_table(X), State).
from_fact(State, X, From,  on(X, From)) :- member(on(X, From), State).

block_in_state(B, State) :- member(on_table(B), State).
block_in_state(B, State) :- member(on(B, _), State).
block_in_state(B, State) :- member(on(_, B), State).

clear(X, State) :- \+ member(on(_, X), State).

%% print_state(+State) - Display a blocks world state
print_state(State) :-
    format("State: ~w~n", [State]).
