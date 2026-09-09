:- module(test_farmer, []).
:- use_module(library(plunit)).
:- use_module('../prolog/farmer').

:- begin_tests(farmer).

test(farmer_has_solution, [nondet]) :-
    solve_farmer(Moves),
    is_list(Moves),
    length(Moves, N),
    N > 0.

test(solution_length_is_7, [nondet]) :-
    % The classic solution crosses the river 7 times.
    solve_farmer(Moves),
    length(Moves, Len),
    Len =:= 7.

test(every_intermediate_state_is_safe, [nondet]) :-
    % Re-simulate the plan; every state along the way must satisfy
    % farmer's safety predicate.
    solve_farmer(Moves),
    Init = state(left, left, left, left),
    simulate(Init, Moves, States),
    forall(member(S, States), farmer_safe(S)).

test(unsafe_state_is_rejected, [fail]) :-
    % Fox and chicken alone together on the right bank while the
    % farmer is on the left must be rejected by safe/1.
    farmer_safe(state(left, right, right, left)).

:- end_tests(farmer).

%% farmer_safe(+State) — call the (unexported) safe/1 via module.
farmer_safe(State) :- farmer:safe(State).

%% simulate(+State, +Moves, -States)
%% Follow Moves from State, collecting every visited state.
simulate(State, [], [State]).
simulate(State, [Move|Moves], [State|States]) :-
    farmer:move(State, Next, Move),
    simulate(Next, Moves, States).
