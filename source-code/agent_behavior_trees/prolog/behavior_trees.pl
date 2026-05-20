:- module(behavior_trees, [
    tick/2,
    define_tree/2
]).

/** <module> Behavior Trees Engine
 *
 * A simple, lightweight, and elegant Behavior Tree implementation in Prolog.
 * Supports:
 *   - sequence([Children])
 *   - selector([Children]) (fallback)
 *   - condition(Name)
 *   - action(Name)
 */

:- dynamic tree_definition/2.

% Define a tree name and its root node
define_tree(Name, RootNode) :-
    retractall(tree_definition(Name, _)),
    assertz(tree_definition(Name, RootNode)).

% Tick the entire tree by name
tick(TreeName, Status) :-
    tree_definition(TreeName, RootNode),
    !,
    tick_node(RootNode, Status).

% --- Node Tick Implementation ---

% 1. Sequence Node: Ticks children in order. 
%    - If a child fails, sequence fails.
%    - If a child returns 'running', sequence returns 'running'.
%    - If all children succeed, sequence succeeds.
tick_node(sequence(Children), Status) :-
    tick_sequence(Children, Status).

% 2. Selector Node (Fallback): Ticks children in order.
%    - If a child succeeds, selector succeeds.
%    - If a child returns 'running', selector returns 'running'.
%    - If all children fail, selector fails.
tick_node(selector(Children), Status) :-
    tick_selector(Children, Status).

% 3. Condition Node: Evaluates a user-defined condition predicate.
%    - Returns 'success' if the condition is true.
%    - Returns 'failure' if the condition is false.
tick_node(condition(CondName), Status) :-
    (   call_condition(CondName)
    ->  Status = success
    ;   Status = failure
    ).

% 4. Action Node: Executes a user-defined action predicate.
%    - The action predicate must bind its status argument (success, failure, or running).
tick_node(action(ActionName), Status) :-
    call_action(ActionName, Status).

% --- Helper Predicates for Composites ---

% Sequence traversal
tick_sequence([], success).
tick_sequence([Child|Rest], Status) :-
    tick_node(Child, ChildStatus),
    (   ChildStatus = success
    ->  tick_sequence(Rest, Status)
    ;   Status = ChildStatus  % either 'failure' or 'running'
    ).

% Selector traversal
tick_selector([], failure).
tick_selector([Child|Rest], Status) :-
    tick_node(Child, ChildStatus),
    (   ChildStatus = failure
    ->  tick_selector(Rest, Status)
    ;   Status = ChildStatus  % either 'success' or 'running'
    ).

% --- Interface to Hook Action & Condition Predicates ---
% User-defined actions and conditions are expected to be defined in user modules
% or hooked into the following dynamic/multifile predicates:
:- multifile user_condition/1.
:- multifile user_action/2.

call_condition(CondName) :-
    user_condition(CondName).

call_action(ActionName, Status) :-
    user_action(ActionName, Status).
