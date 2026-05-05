# Meta-Interpreters: Prolog Reasoning About Prolog

Meta-interpreters are one of Prolog's most unique and powerful capabilities. A meta-interpreter is a Prolog program that interprets Prolog programs, allowing us to modify, extend, or instrument the reasoning process itself.

## The Vanilla Meta-Interpreter

TBD: The simplest meta-interpreter — a Prolog interpreter written in Prolog. Understanding `clause/2` and how the meta-interpreter mirrors Prolog's own execution.

The **meta_interp** project provides both a vanilla and bounded meta-interpreter. Here is the file **meta_interp/prolog/vanilla.pl**:

```prolog
%% vanilla.pl - Vanilla meta-interpreter and proof-tree variant
:- module(vanilla, [
    mi_solve/1, mi_solve/2,
    mi_solve_proof/2, mi_solve_proof/3
]).

%% mi_solve(+Goal) - Vanilla meta-interpreter (user module context)
mi_solve(Goal) :- mi_solve(user, Goal).

%% mi_solve(+Module, +Goal) - With module context
mi_solve(_, true) :- !.
mi_solve(Mod, (A, B)) :- !, mi_solve(Mod, A), mi_solve(Mod, B).
mi_solve(Mod, Goal) :-
    clause(Mod:Goal, Body),
    mi_solve(Mod, Body).

%% mi_solve_proof(+Goal, -Proof) - With proof tree (user module)
mi_solve_proof(Goal, Proof) :- mi_solve_proof(user, Goal, Proof).

%% mi_solve_proof(+Module, +Goal, -Proof)
mi_solve_proof(_, true, true) :- !.
mi_solve_proof(Mod, (A, B), (PA, PB)) :- !,
    mi_solve_proof(Mod, A, PA),
    mi_solve_proof(Mod, B, PB).
mi_solve_proof(Mod, Goal, Goal-Proof) :-
    clause(Mod:Goal, Body),
    mi_solve_proof(Mod, Body, Proof).
```

## Adding Proof Trees

TBD: Extending the meta-interpreter to build and return a proof tree, showing exactly how a conclusion was derived. This is the foundation for explanation facilities.

The **proof_trees** project provides a standalone proof tree builder. Here is the file **proof_trees/prolog/proof_tree.pl**:

```prolog
%% proof_tree.pl - Build and display proof trees for explainable reasoning
:- module(proof_tree, [prove_with_tree/2, print_proof/1]).

%% prove_with_tree(+Goal, -Tree)
prove_with_tree(true, leaf(true)) :- !.
prove_with_tree((A, B), and(PA, PB)) :- !,
    prove_with_tree(A, PA),
    prove_with_tree(B, PB).
prove_with_tree(Goal, node(Goal, ChildProofs)) :-
    clause(Goal, Body),
    prove_with_tree(Body, ChildProofs).

%% print_proof(+Tree) - Pretty-print with indentation
print_proof(Tree) :- print_proof(Tree, 0).

print_proof(leaf(true), Indent) :-
    tab(Indent), format("✓ true~n").
print_proof(and(A, B), Indent) :-
    print_proof(A, Indent),
    print_proof(B, Indent).
print_proof(node(Goal, Children), Indent) :-
    tab(Indent), format("├─ ~w~n", [Goal]),
    Indent1 is Indent + 3,
    print_proof(Children, Indent1).
```

## Bounded Reasoning

TBD: A meta-interpreter that limits the depth of search to prevent infinite loops and control resource usage — useful for reasoning over untrusted or cyclic knowledge bases.

Here is the file **meta_interp/prolog/bounded.pl**:

```prolog
%% bounded.pl - Bounded depth meta-interpreter
:- module(bounded, [mi_bounded/2, mi_bounded/3]).

%% mi_bounded(+Goal, +MaxDepth) - Solve with depth limit (user module)
mi_bounded(Goal, MaxDepth) :- mi_bounded(user, Goal, MaxDepth).

%% mi_bounded(+Module, +Goal, +MaxDepth)
mi_bounded(_, true, _) :- !.
mi_bounded(_, _, D) :- D =< 0, !, fail.
mi_bounded(Mod, (A, B), D) :- !,
    mi_bounded(Mod, A, D),
    mi_bounded(Mod, B, D).
mi_bounded(Mod, Goal, D) :-
    D > 0,
    clause(Mod:Goal, Body),
    D1 is D - 1,
    mi_bounded(Mod, Body, D1).
```

## Reasoning with Uncertainty

TBD: A meta-interpreter that propagates certainty factors or probabilities through the inference process, combining logical and probabilistic reasoning.

## Custom Search Strategies

TBD: Writing meta-interpreters that implement breadth-first, iterative deepening, or best-first search strategies instead of Prolog's default depth-first approach.

## Debugging and Tracing Meta-Interpreters

TBD: Building custom tracers and debuggers as meta-interpreters. Instrumenting programs for performance analysis.
