# Planning and Scheduling

Planning, finding a sequence of actions that reaches a goal, is one of the oldest problems in AI. Prolog suits it well: you describe the actions, and backtracking search finds the plan. In this chapter we build a STRIPS planner, a dedicated blocks world planner, and a scheduler, and look at partial-order planning.


## Classical Planning in Prolog

Classical planning represents the world as a set of logical **fluents**, facts that can be true or false at any given time. A **state** is a collection of fluents that hold true. Actions change the state by adding and deleting fluents, and a plan is a sequence of actions that transforms an initial state into one that satisfies a goal condition.

The most influential representation is **STRIPS** (STanford Research Institute Problem Solver), where each action is defined by three components:

- **Preconditions**: fluents that must be true for the action to be applicable.
- **Add list**: fluents made true by the action.
- **Delete list**: fluents made false by the action.

Dear reader, this is old technology, but it is still worth understanding. Richard Fikes and Nils Nilsson built STRIPS in 1971 at the Stanford Research Institute (SRI) to plan the actions of Shakey the robot. Its way of describing actions, by preconditions, an add list, and a delete list, is still the basis of planning languages such as PDDL. By keeping the description of actions apart from the search, STRIPS avoided much of the cost of earlier planners that used general theorem proving.

A STRIPS action schema uses variables so a single definition covers many concrete instances. For example, `pickup(X)` applies to any block `X` on the table with nothing on top of it.

{width: "80%"}
![Architecture diagram for the STRIPS Planner example](FIG_strips_planner.jpg)

The **strips_planner** project implements the core algorithm and two practical variants. Here is the file **strips_planner/prolog/strips.pl**:

```prolog
%% strips.pl - STRIPS-style planner with multiple domains
:- module(strips, [
    plan/3,
    plan_bfs/3,
    plan_visited/3,
    valid_state/1,
    action/4,
    holds/2
]).

%% holds(+Conditions, +State)
%% True when every condition in Conditions is present in State.
%% Uses member/2 (not memberchk) so that variables in Conditions
%% can be bound to any matching element in State.
holds([], _).
holds([C|Cs], State) :- member(C, State), holds(Cs, State).

%% plan(+InitState, +GoalState, -Plan)
%% Iterative-deepening search: plan_dfs/4 is run with depth limits
%% 1, 2, ..., 50 in turn.  Unlike plain DFS this always terminates
%% and finds a shortest plan; on exhaustion (no plan within the
%% depth bound) it fails cleanly.
plan(State, Goal, Plan) :-
    between(1, 50, Depth),
    plan_dfs(State, Goal, Depth, Plan), !.

%% plan_dfs(+State, +Goal, +DepthLeft, -Plan)
plan_dfs(State, Goal, _DepthLeft, []) :-
    holds(Goal, State).
plan_dfs(State, Goal, DepthLeft, [Action|Plan]) :-
    DepthLeft > 0,
    action(Action, Preconditions, AddList, DeleteList),
    holds(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    DepthLeft1 is DepthLeft - 1,
    plan_dfs(NewState, Goal, DepthLeft1, Plan).

%% plan_bfs(+InitState, +GoalState, -Plan)
%% Breadth-first search, guaranteed to find a shortest plan.
%% States are normalized with sort/2 and kept in a visited set so
%% each distinct state is enqueued at most once.
plan_bfs(State, Goal, Plan) :-
    sort(State, Key),
    plan_bfs_queue([bfs_node(State, [])], Goal, [bfs_key(Key)], RevPlan),
    reverse(RevPlan, Plan).

plan_bfs_queue([bfs_node(State, Actions)|_], Goal, _Seen, Actions) :-
    holds(Goal, State), !.
plan_bfs_queue([bfs_node(State, Actions)|Rest], Goal, Seen, Plan) :-
    findall(
        bfs_node(NewState, [Action|Actions]),
        (   action(Action, Preconditions, AddList, DeleteList),
            holds(Preconditions, State),
            subtract(State, DeleteList, TempState),
            union(TempState, AddList, NewState)
        ),
        Children
    ),
    % Normalize each child state with sort/2 and enqueue only
    % distinct states that have not been seen before.
    bfs_enqueue_unseen(Children, Seen, Fresh, Seen1),
    append(Rest, Fresh, NewQueue),
    plan_bfs_queue(NewQueue, Goal, Seen1, Plan).

%% Drop children whose sort/2-normalized state (wrapped in
%% bfs_key/1) has already been seen; add the kept states' keys.
bfs_enqueue_unseen([], Seen, [], Seen).
bfs_enqueue_unseen([bfs_node(S, _)|Nodes], Seen, Fresh, Seen1) :-
    sort(S, K),
    memberchk(bfs_key(K), Seen),
    !,
    bfs_enqueue_unseen(Nodes, Seen, Fresh, Seen1).
bfs_enqueue_unseen([bfs_node(S, A)|Nodes], Seen,
                   [bfs_node(S, A)|Fresh], Seen1) :-
    sort(S, K),
    bfs_enqueue_unseen(Nodes, [bfs_key(K)|Seen], Fresh, Seen1).

%% plan_visited(+InitState, +GoalState, -Plan)
%% DFS with cycle detection: never revisits a state on the current path.  The
%% visited set is passed as an explicit argument, so backtracking
%% automatically unwinds it (no surviving assertz leaks) and every
%% top-level call starts from a fresh set.
plan_visited(State, Goal, Plan) :-
    sort(State, Key),
    plan_visited_dfs(State, Goal, [Key], Plan).

plan_visited_dfs(State, Goal, _Visited, []) :-
    holds(Goal, State), !.
plan_visited_dfs(State, Goal, Visited, [Action|Plan]) :-
    action(Action, Preconditions, AddList, DeleteList),
    holds(Preconditions, State),
    subtract(State, DeleteList, TempState),
    union(TempState, AddList, NewState),
    sort(NewState, Key),
    \+ memberchk(Key, Visited),
    plan_visited_dfs(NewState, Goal, [Key|Visited], Plan).

%% valid_state(+State)
%% True when State (a list of fluents) contains no basic
%% contradictions: nothing may be both clear and have a block on
%% it, and nothing may be held while the hand is empty.
valid_state(State) :-
    \+ ( member(on(_, Y), State), member(clear(Y), State) ),
    \+ ( member(holding(_), State), member(hand_empty, State) ).
```

### How the Planner Works

The planner provides three search strategies, all built on the same action interface:

**Iterative deepening (`plan/3`)** runs the depth-limited `plan_dfs/4` with limits 1, 2, ..., 50. Unlike plain DFS it always terminates, and the first plan it finds is a shortest one. It fails if no plan of 50 steps or fewer exists.

**Breadth-first search (`plan_bfs/3`)** keeps a queue of `bfs_node(State, RevActions)` terms and expands every node at depth *d* before any at depth *d+1*, so the first plan it finds has the fewest actions. States are sorted with `sort/2`, so the same set of fluents in another order counts as the same state, and each state enters the queue once. The cost is memory, since the queue can grow large.

**DFS with cycle detection (`plan_visited/3`)** carries the states on the current path as an argument and never returns to one of them. Because the list is an argument, backtracking undoes it for free. It does *not* promise a shortest plan.

`valid_state/1` checks a hand-written state for simple contradictions, such as a block that is both clear and has a block on it. It is a sanity check, not part of the search.

### The `holds/2` Predicate

We define `holds/2` with `member/2` rather than the library's `subset/2`. `subset/2` uses `memberchk/2`, which commits to the first match. A variable such as `X` in `pickup(X)` would then always bind to the first block found, and `findall/3` would never see actions for the other blocks. `member/2` lets backtracking try every binding.

### Running the Planner

Here is a simple blocks-world query using the iterative-deepening planner:

```prolog
?- plan([on_table(a), clear(a), hand_empty], [holding(a)], Plan).
Plan = [pickup(a)].
```

For the two-block stacking problem, BFS finds the optimal 2-step plan:

```prolog
?- plan_bfs([on_table(a), on_table(b), clear(a), clear(b), hand_empty],
            [on(a, b)], Plan).
Plan = [pickup(a), stack(a, b)].
```

Building a three-block tower, BFS finds the minimal 4-step sequence:

```prolog
?- plan_bfs([on_table(a), on_table(b), on_table(c),
             clear(a), clear(b), clear(c), hand_empty],
            [on(a, b), on(b, c)], Plan).
Plan = [pickup(b), stack(b, c), pickup(a), stack(a, b)].
```

### Domain Definitions

The same planner works for any domain once the actions are defined. The blocks world uses four operators:

```prolog
action(pickup(X),
    [on_table(X), clear(X), hand_empty],
    [holding(X)],
    [on_table(X), clear(X), hand_empty]).

action(stack(X, Y),
    [holding(X), clear(Y)],
    [on(X, Y), clear(X), hand_empty],
    [holding(X), clear(Y)]).
```

The logistics domain, with trucks and planes moving packages, uses distinct predicate names (`pkg_at/2`, `truck_at/2`, `plane_at/2`) so that action-schema variables bind to the correct entity types:

```prolog
action(load_truck(Pkg, Truck, Loc),
    [pkg_at(Pkg, Loc), truck_at(Truck, Loc), free(Truck)],
    [in(Pkg, Truck)],
    [pkg_at(Pkg, Loc), free(Truck)]).

action(drive(Truck, From, To),
    [truck_at(Truck, From), road(From, To)],
    [truck_at(Truck, To)],
    [truck_at(Truck, From)]).
```

A logistics query, shipping a package from `loc_a` to `loc_b` using a truck:

```prolog
?- plan_bfs([pkg_at(pkg1, loc_a), truck_at(truck1, loc_a), free(truck1),
             road(loc_a, loc_b), road(loc_b, loc_a)],
            [pkg_at(pkg1, loc_b)], Plan).
Plan = [load_truck(pkg1, truck1, loc_a),
        drive(truck1, loc_a, loc_b),
        unload_truck(pkg1, truck1, loc_b)].
```

The planner and the domains are separate: to add a domain, write `action/4` facts; the search code does not change.


## The Blocks World

The blocks world is the classic planning domain: a robot arm stacks and unstacks labeled blocks on a table to reach a goal arrangement. It is simple enough to reason about, yet it shows the core problems of planning: search, state representation, and the frame problem (saying what an action does *not* change).

{width: "80%"}
![Architecture diagram for the Blocks World planner](FIG_blocks_world.jpg)

The STRIPS planner can solve blocks world problems, but the **blocks_world** project uses a simpler representation with one kind of move. Here is the file **blocks_world/prolog/blocks.pl**:

```prolog
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
```

### Design Decisions

**Moves.** Instead of add and delete lists, `blocks_move/3` edits the state list: `select/3` removes the block's old position and the new `on/2` or `on_table/1` fact goes on the front. Moves read naturally, such as `move(a, table, b)`. `from_fact/4` lets one clause move a block from the table or from another block.

**Derived facts.** The state holds only `on/2` and `on_table/1`. A block is clear when nothing is on it: `clear(X, State) :- \+ member(on(_, X), State)`. Deriving `clear` instead of storing it means no action can forget to update it, which is one answer to the frame problem.

**Search.** `blocks_plan/3` is breadth-first, with a list of states already queued, so it returns a shortest plan. `blocks_plan_dfs/3` is depth-first with a visited list, for comparison. The goal is a list of facts that must all hold, usually just the `on/2` facts you want.

### Example Queries

Stack block `a` on block `b`:

```prolog
?- blocks_plan([on_table(a), on_table(b)], [on(a, b)], Moves).
Moves = [move(a, table, b)].
```

The **Sussman anomaly** is a famous test. Block `c` sits on `a`, and the goal is a tower `a` on `b` on `c`:

```prolog
?- blocks_plan([on(c, a), on_table(a), on_table(b)],
               [on(a, b), on(b, c)], Moves).
Moves = [move_to_table(c, a), move(b, table, c), move(a, table, b)].
```

Early planners that worked on one goal at a time failed here: putting `a` on `b` first blocks the way to `b` on `c`, and doing `b` on `c` first buries `a`. Searching whole states avoids the trap. Depth-first search also finds a plan, but not the shortest:

```prolog
?- blocks_plan_dfs([on(c, a), on_table(a), on_table(b)],
                   [on(a, b), on(b, c)], Moves).
Moves = [move(c, a, b), move_to_table(c, b), move(b, table, c),
         move(a, table, b)].
```

DFS moves `c` onto `b` and then straight back off, a wasted move. On larger problems, depth-first plans can be much longer than needed.


## Planning with Constraints

Classical STRIPS planning answers *what to do*, but real-world problems also demand answers to *when* and *with what resources*. **Constraint Logic Programming** over finite domains (CLP(FD)) extends planning with temporal reasoning, resource limits, and scheduling constraints, all while retaining Prolog's declarative style.

### Temporal Constraints on Actions

In a pure STRIPS plan, actions have no duration and execute instantaneously. Adding time transforms planning into scheduling: each action occupies a time interval, and these intervals must respect ordering and resource constraints.

The CLP(FD) approach models each action's start time as a finite-domain variable:

- **Precedence**: If action *B* must follow action *A*, constrain `StartB #>= EndA`.
- **Deadlines**: If an action must finish by time *T*, constrain `End #=< T`.
- **Duration**: `End #= Start + Duration`.

These integer constraints propagate through the constraint network. When a start time's domain is reduced, the solver automatically tightens the domains of linked actions, pruning the search space before any concrete time is assigned.

### Hybrid Planning and Scheduling

A practical architecture separates the two concerns:

1. A **STRIPS planner** (like the ones in the previous sections) finds a valid action sequence.
2. A **constraint solver** assigns times and resources to that sequence.

This division works because the causal structure (what actions are needed and in what order) is often independent of the temporal structure (exactly when each action executes). For problems where action choice depends on timing, such as selecting a faster but costlier machine over a slower cheaper one, the two layers can interleave: the planner proposes a partial plan, the scheduler checks feasibility, and backtracking drives the combined search.

### A Constraint-Based Scheduler

The companion project **job_scheduler** (described fully in the Constraint Logic Programming chapter) demonstrates the scheduling layer. Here is the file **job_scheduler/prolog/scheduler.pl**:

```prolog
schedule_jobs(Jobs, Schedule) :-
    horizon(Jobs, Horizon),
    maplist(create_task(Horizon), Jobs, Schedule, Starts),
    maplist(deadline_constraint, Jobs, Schedule),
    no_overlap(Schedule),
    makespan(Schedule, Makespan),
    labeling([min(Makespan)], Starts).

%% horizon(+Jobs, -Horizon)
%% No job needs to start later than the total work: any feasible
%% schedule can be shifted left until it has no idle time.
horizon(Jobs, Horizon) :-
    foldl(add_duration, Jobs, 0, Horizon).

add_duration(job(_, Duration, _), Sum0, Sum) :-
    Sum is Sum0 + Duration.

create_task(Horizon, job(Name, Duration, _Deadline),
            scheduled(Name, Start, End), Start) :-
    Start in 0..Horizon,
    End #= Start + Duration.

deadline_constraint(job(_, _, Deadline), scheduled(_, _, End)) :-
    (   integer(Deadline)
    ->  End #=< Deadline
    ;   true
    ).

%% no_overlap(+Schedule)
%% Posts constraints so that no two jobs overlap: for each pair, one
%% job ends before the other starts. #\/ is a constraint
%% disjunction, so the solver decides the order by propagation and
%% search instead of by Prolog backtracking.
no_overlap([]).
no_overlap([Task|Tasks]) :-
    maplist(disjoint(Task), Tasks),
    no_overlap(Tasks).

disjoint(scheduled(_, S1, E1), scheduled(_, S2, E2)) :-
    E1 #=< S2 #\/ E2 #=< S1.

%% makespan(+Schedule, -Makespan)
%% Makespan is the largest end time in Schedule.
makespan(Schedule, Makespan) :-
    maplist(end_time, Schedule, Ends),
    max_list_fd(Ends, Makespan).

end_time(scheduled(_, _, End), End).

max_list_fd([E|Es], Max) :-
    foldl(fd_max, Es, E, Max).

fd_max(E, M0, M) :-
    M #= max(M0, E).
```

The scheduler handles three kinds of constraint:

1. **Capacity**: `no_overlap/1` keeps the jobs from overlapping on the one machine, with a disjunctive constraint for each pair, so the solver chooses the order.
2. **Deadlines**: each job's `End` must not exceed its deadline.
3. **Makespan**: `labeling([min(Makespan)], Starts)` looks for the schedule that finishes earliest.

`no_overlap/1` posts constraints on unbound variables; to check a finished schedule, use `schedule_valid/1`.

A six-job problem with tight deadlines:

```prolog
?- schedule_jobs([job(a, 3, 5), job(b, 2, 6), job(c, 4, 10),
                  job(d, 1, 11), job(e, 2, 13), job(f, 5, 18)], Schedule).
Schedule = [scheduled(a,0,3), scheduled(b,3,5), scheduled(c,5,9),
            scheduled(d,9,10), scheduled(e,10,12), scheduled(f,12,17)].
```

With six jobs and no gaps, the schedule finishes at time 17, the total work, so no schedule can finish sooner. Each job also meets its deadline.


## Partial-Order Planning

Total-order planners (like the STRIPS examples above) produce fully ordered sequences of actions. But many actions are independent: moving a package from Boston to Chicago and loading a different truck in Seattle can happen in either order, or simultaneously. **Partial-order planning** (POP) exploits this independence, producing a plan as a set of actions with ordering constraints only where necessary.

### Causal Links and Threats

A partial-order plan is a directed acyclic graph where:

- **Nodes** are actions, plus two special nodes: *Start* (producing the initial state) and *Finish* (requiring the goal).
- **Ordering constraints** specify that action *A* must precede action *B*.
- **Causal links** record that action *A* produces fluent *p* for action *B* to consume. Written as *A* ⟶^p *B*, a causal link means "A achieves precondition p of B."

Planning proceeds by selecting an **open precondition**, a fluent needed by some action that is not yet linked to a producer, and either:

1. Find an existing action whose effects include that fluent and add a causal link, or
2. Add a new action to the plan that produces it.

Adding a causal link can create a **threat**: an action *C* that deletes the linked fluent and could fall between *A* and *B*. There are two fixes. **Demotion** orders *C* before *A*, and **promotion** orders *C* after *B* (the terms follow Russell and Norvig's *Artificial Intelligence: A Modern Approach*). If neither ordering is consistent, the planner backtracks.

### Why Partial-Order Planning Matters

POP produces **least-commitment** plans. By not imposing unnecessary orderings, the resulting plan admits many valid linearizations. This matters when:

- **Several agents** carry out the plan: independent actions can run in parallel.
- **Durations are uncertain**: a later action may become ready before an earlier one finishes.
- **Replanning** is needed during execution: two unordered actions can be swapped without breaking the plan.

### Implementing POP in Prolog

Prolog's unification and backtracking map cleanly onto the POP algorithm. A partial plan can be represented as a structure:

```prolog
plan(Actions, Orderings, CausalLinks, OpenPreconditions)
```

The main loop picks an open precondition, chooses a way to achieve it, adds the ordering and causal-link constraints, resolves any threats, and recurses. Prolog's backtracking handles the choices: when threat resolution fails, Prolog tries the next option.

A full POP planner is beyond the scope of this chapter. This sketch shows the key data structures; it is not part of the companion code:

```prolog
%% A causal link: Producer achieves Precondition for Consumer
causal_link(Producer, Precondition, Consumer)

%% A threat: Deleter deletes Precondition, which is protected
%% by a causal link from Producer to Consumer
threat(Deleter, Precondition, Producer, Consumer)

%% Resolve a threat by ordering Deleter before Producer (demotion)
%% or after Consumer (promotion), if consistent with the orderings
resolve_threat(Threat, Plan, NewPlan) :-
    (   demote(Threat, Plan, NewPlan)
    ;   promote(Threat, Plan, NewPlan)
    ).
```

A partial-order plan stands for a whole *family* of linear plans: every topological sort of the final plan graph is a valid way to carry it out.


## Practical Job Scheduling Applications

Planning and scheduling go well beyond blocks and packages. This section surveys real applications where Prolog's planning and constraint solving help.

{width: "80%"}
![Architecture diagram for the Job Scheduler example](FIG_job_scheduler.jpg)

### Project Scheduling with Resource Constraints

Construction projects, software releases, and factories share a structure: tasks with durations, ordering requirements, and limited shared resources (crews, machines, specialists). The constraint approach from earlier sections extends to them:

- **Resource pools** replace the single machine. Instead of `no_overlap/1`, the CLP(FD) constraint `cumulative(Tasks, [limit(L)])` keeps the total demand at every moment at or below `L`, where each task is `task(Start, Duration, End, Demand, Id)`.
- **Precedence networks** capture task dependencies: "the foundation must be poured before the framing begins." These are modeled as `StartB #>= EndA` constraints, just like in the job scheduler.
- **Milestones** tie the schedule to calendar dates: the launch, the conference deadline, the filing date.

### Timetabling

Course schedules, conference programs, and staff shifts are timetabling problems: assign events to time slots and rooms, with hard constraints (no room booked twice, teachers available) and soft preferences (back-to-back lectures in the same building).

In CLP(FD), rules become constraints. "Professor Smith cannot teach before 10 AM" restricts the domain of a start-time variable. "Room 101 seats 50" becomes a constraint that a class with more than 50 students is not in room 101. Soft preferences become terms in a cost to minimize.

### Integration with External Solvers

For large industrial problems, Prolog often works as the **modeling and control layer** rather than the solver itself. The Prolog program:

1. Reads the problem specification (tasks, resources, constraints) from a database or file.
2. Builds a constraint model in Prolog using CLP(FD) for rapid prototyping.
3. For production, exports the model to a dedicated solver (OR-Tools, CPLEX, Gurobi) via a file interface or foreign function binding.
4. Reads back the solution and validates it against the original constraints.

This combines Prolog's readable models and fast iteration with the speed of specialized solvers on large instances. SWI-Prolog supports it through its C foreign interface and libraries for common data formats.

### The Prolog Advantage

Why use Prolog for scheduling? Three reasons:

1. **Constraints read like the problem.** "Task A ends before task B starts" becomes `EndA #=< StartB`, with no search or propagation code to write.
2. **Backtracking is built in.** When a partial schedule cannot work, Prolog returns to the last choice and tries another.
3. **Fast prototyping.** The job scheduler in this book is under 100 lines. A specialized solver may run faster on 10,000 tasks, but the Prolog model is a quick way to get the rules right first.

## Optional Practice Problems

1. **Negative Preconditions**: Extend `action/4` in `strips_planner` so a precondition can be `not(F)`, meaning fluent `F` must be absent. Change `holds/2` and add a test.
2. **Workers as a Resource**: Change `job_scheduler` so jobs need a number of workers each and up to `W` workers exist, using `cumulative/2` instead of `no_overlap/1`.
3. **Plan then Schedule**: Give each blocks world move a duration of 1, and two robot arms. Use `blocks_plan/3` to get a plan, then CLP(FD) to schedule its moves on the two arms, keeping each move after the moves it depends on.
