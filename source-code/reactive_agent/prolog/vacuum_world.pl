%% vacuum_world.pl - The two-room vacuum cleaner world, a classic
%% reactive agent example
:- module(vacuum_world, [
    setup_world/2,
    perceive/0,
    select_action/1
]).

:- use_module(agent).

%% The environment: where the robot is, and which rooms are dirty.
:- dynamic robot_at/1, dirty/1.

%% setup_world(+Room, +DirtyRooms)
%% Put the robot in Room (a or b), make DirtyRooms dirty, and set up
%% the agent's goal and tools.
setup_world(Room, DirtyRooms) :-
    reset_agent,
    retractall(robot_at(_)),
    retractall(dirty(_)),
    assertz(robot_at(Room)),
    forall(member(R, DirtyRooms), assertz(dirty(R))),
    define_goal(all_clean),
    register_tool(suck, suck),
    register_tool(move_left, move_to(a)),
    register_tool(move_right, move_to(b)).

%% perceive: the robot senses only its own room. It remembers which
%% rooms it has seen clean.
perceive :-
    robot_at(Room),
    remove_belief(location(_)),
    add_belief(location(Room)),
    (   dirty(Room)
    ->  remove_belief(clean(Room)),
        add_belief(dirty(Room))
    ;   remove_belief(dirty(Room)),
        add_belief(clean(Room))
    ),
    (   belief(clean(a)), belief(clean(b))
    ->  add_belief(all_clean)
    ;   remove_belief(all_clean)
    ).

%% select_action(-Action): condition-action rules, tried in order.
select_action(suck) :-
    belief(location(R)), belief(dirty(R)), !.
select_action(move_right) :-
    belief(location(a)), \+ belief(clean(b)), !.
select_action(move_left) :-
    belief(location(b)), \+ belief(clean(a)), !.

%% The tools change the environment, not the beliefs; the agent sees
%% the result at its next perceive step.
suck :-
    robot_at(Room),
    retractall(dirty(Room)).

move_to(Room) :-
    retractall(robot_at(_)),
    assertz(robot_at(Room)).
