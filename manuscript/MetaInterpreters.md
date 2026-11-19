# Meta-Interpreters: Prolog Reasoning About Prolog

A meta-interpreter is a Prolog program that runs Prolog programs. With one, we can change, extend, or watch the reasoning process itself. This is a form of *reflection*: the program treats its own rules and facts as data to inspect and run under new policies.

In most languages, changing how code runs (adding tracing, limiting recursion depth, trying another search order, or attaching certainty scores) means changing the compiler or runtime, or writing a separate tool. In Prolog, it takes a few lines of Prolog. The meta-interpreter sees every resolution step and decides what to do with it, which makes it useful for explainable AI, debugging, and reasoning with limited resources.

{width: "80%"}
![Architecture diagram for the Meta-Interpreter example](FIG_meta_interp.jpg)

## The Vanilla Meta-Interpreter

The simplest meta-interpreter, the "vanilla" meta-interpreter, is a Prolog interpreter written in Prolog. Short as it is, it follows Prolog's own execution model: depth-first search, goals left to right, clauses top to bottom.

The key built-in is `clause(Head, Body)`. Given a goal `Head`, it returns each matching clause in turn, binding `Body` to the clause body (or `true` for a fact). This is how a meta-interpreter "sees" the program it runs.

The vanilla meta-interpreter has four clauses, one for each kind of goal:

1. **The goal `true`** succeeds. The cut stops the other clauses from trying it too.

2. **A conjunction `(A, B)`**: solve `A` (which may bind variables), then `B`.

3. **A built-in predicate**, such as `is/2`, detected with `predicate_property(Mod:Goal, built_in)`: call it directly. Built-ins have no clauses for `clause/2` to read; calling `clause/2` on one raises a permission error.

4. **Any other goal**: find a matching clause with `clause/2` and solve its body. If no clause matches, the goal fails. If several match, backtracking tries each.

Every meta-interpreter in this chapter starts from these four clauses and changes one or more of them.

The **meta_interp** project has six meta-interpreters. Here is the first, **meta_interp/prolog/vanilla.pl**:

```prolog
:- module(vanilla, [
    mi_solve/1,
    mi_solve/2,
    mi_solve_proof/2,
    mi_solve_proof/3
]).

%% mi_solve(+Goal) - Vanilla meta-interpreter (user module context)
mi_solve(Goal) :- mi_solve(user, Goal).

%% mi_solve(+Module, +Goal)
%% Vanilla meta-interpreter with module context
mi_solve(_, true) :- !.
mi_solve(Mod, (A, B)) :- !, mi_solve(Mod, A), mi_solve(Mod, B).
mi_solve(Mod, Goal) :-
    predicate_property(Mod:Goal, built_in),
    !,
    call(Mod:Goal).
mi_solve(Mod, Goal) :-
    clause(Mod:Goal, Body),
    mi_solve(Mod, Body).

%% mi_solve_proof(+Goal, -Proof)
%% Meta-interpreter with proof tree (user module)
mi_solve_proof(Goal, Proof) :- mi_solve_proof(user, Goal, Proof).

%% mi_solve_proof(+Module, +Goal, -Proof) - With module context
mi_solve_proof(_, true, true) :- !.
mi_solve_proof(Mod, (A, B), (PA, PB)) :- !,
    mi_solve_proof(Mod, A, PA),
    mi_solve_proof(Mod, B, PB).
mi_solve_proof(Mod, Goal, Goal-builtin) :-
    predicate_property(Mod:Goal, built_in),
    !,
    call(Mod:Goal).
mi_solve_proof(Mod, Goal, Goal-Proof) :-
    clause(Mod:Goal, Body),
    mi_solve_proof(Mod, Body, Proof).
```

The versions with a module argument (`mi_solve/2` and `mi_solve_proof/3`) look clauses up with `clause(Mod:Goal, Body)`, so the interpreter can run predicates defined in any module, not just its own. `mi_solve_proof/3` also returns a proof term, with built-in goals recorded as `Goal-builtin`:

```prolog
?- mi_solve_proof(sample_kb, grandparent(tom, W), P).
W = ann,
P = grandparent(tom,ann)-(parent(tom,bob)-true,parent(bob,ann)-true).
```

## Adding Proof Trees

A meta-interpreter that only succeeds or fails tells us *whether* a conclusion follows, not *why*. When a system must justify its reasoning to a user, an auditor, or another program, we need the steps it took. A **proof tree** records them: each goal proved, the clause used, and the sub-proofs it needed.

The Reasoning chapter introduced the **proof_trees** project. It loads a five-generation family tree from **prolog/sample_data.pl**, with 28 `parent/2` facts and 7 rules:

| Predicate | Type | Description |
|---|---|---|
| `parent/2` | Facts (28) | Direct parent-child relationships across 5 generations |
| `grandparent/2` | Rule | Conjunction of two `parent/2` subgoals |
| `great_grandparent/2` | Rule | Multi-step derivation via `grandparent` and `parent` |
| `ancestor/2` | Rule (recursive) | Two clauses: direct parent or recursive ancestor chain |
| `descendant/2` | Rule | Inverse of `ancestor/2` |
| `sibling/2` | Rule | Shared parent with inequality check (`\=/2`) |
| `cousin/2` | Rule | Shared grandparent, explicitly not siblings (uses `\+/1`) |
| `aunt_uncle/2` | Rule | Sibling of a parent |

Here is **proof_trees/prolog/proof_tree.pl**:

```prolog
:- module(proof_tree, [
    prove_with_tree/2,
    print_proof/1,
    sample_data_loaded/0
]).

%% sample_data_loaded
%% Load sample_data.pl from the directory that holds this file, so
%% the module works from any working directory. The clauses load
%% into this module, where clause/2 below can see them.
sample_data_loaded :-
    source_file(proof_tree:prove_with_tree(_, _), File),
    file_directory_name(File, Dir),
    directory_file_path(Dir, 'sample_data.pl', Data),
    consult(Data).

:- initialization(sample_data_loaded).

%% prove_with_tree(+Goal, -Tree) - Prove and return proof tree
prove_with_tree(true, leaf(true)) :- !.
prove_with_tree((A, B), and(PA, PB)) :- !,
    prove_with_tree(A, PA),
    prove_with_tree(B, PB).
%% Built-in predicates such as \+, \=, and is/2 have no clauses for
%% clause/2 to read, so we call them and record a leaf.
prove_with_tree(Goal, node(Goal, leaf(Goal))) :-
    predicate_property(Goal, built_in), !,
    call(Goal).
%% User-defined goals: look up clauses and recurse
prove_with_tree(Goal, node(Goal, ChildProofs)) :-
    clause(Goal, Body),
    prove_with_tree(Body, ChildProofs).

%% print_proof(+Tree) - Pretty-print a proof tree with indentation
print_proof(Tree) :- print_proof(Tree, 0).

print_proof(leaf(true), Indent) :- !,
    tab(Indent), format("✓ true~n").
print_proof(leaf(Goal), Indent) :-
    tab(Indent), format("✓ ~w~n", [Goal]).
print_proof(and(A, B), Indent) :-
    print_proof(A, Indent),
    print_proof(B, Indent).
print_proof(node(Goal, Children), Indent) :-
    tab(Indent), format("├─ ~w~n", [Goal]),
    Indent1 is Indent + 3,
    print_proof(Children, Indent1).
```

### Handling Built-in Predicates

Built-in predicates need care in proof trees. Goals such as `X \= Y` in `sibling/2` and `\+ sibling(X, Y)` in `cousin/2` have no clauses, and `clause/2` raises a permission error on them. `prove_with_tree/2` checks `predicate_property(Goal, built_in)`, calls the goal directly, and records a leaf node that holds the goal. So the printed tree shows lines such as `✓ ann\=bob` and `✓ \+sibling(carol,emma)`, which keep every step of the reasoning visible.

Note that `\+ G` appears as a single leaf: the tree records that `G` could not be proved, but not the failed search behind that. Explaining a *failure* is harder than explaining a success, which is why the s(CASP) chapter matters.

### Proof Trees in Action

Here is real output for queries over the sample data, each showing a different kind of reasoning:

**Direct fact lookup** is the simplest possible proof:
```
├─ parent(adam,john)
   ✓ true
```
A single clause lookup finds `parent(adam, john)` as a fact (body `true`), producing a one-level tree.

**Conjunction**: `grandparent(john, ann)` requires proving two subgoals:
```
├─ grandparent(john,ann)
   ├─ parent(john,mary)
      ✓ true
   ├─ parent(mary,ann)
      ✓ true
```
The meta-interpreter decomposes the conjunction into `parent(john, mary)` and `parent(mary, ann)`, proving each independently. The tree structure mirrors the logical structure of the rule `grandparent(X, Z) :- parent(X, Y), parent(Y, Z)`.

**Recursive descent**: a 5-generation ancestor chain from Adam to Grace:
```
├─ ancestor(adam,grace)
   ├─ parent(adam,john)
      ✓ true
   ├─ ancestor(john,grace)
      ├─ parent(john,mary)
         ✓ true
      ├─ ancestor(mary,grace)
         ├─ parent(mary,ann)
            ✓ true
         ├─ ancestor(ann,grace)
            ├─ parent(ann,carol)
               ✓ true
            ├─ ancestor(carol,grace)
               ├─ parent(carol,grace)
                  ✓ true
```
This tree traces the line adam, john, mary, ann, carol, grace. Each level adds a `parent/2` leaf and a recursive `ancestor/2` goal, until the base case `parent(carol, grace)` ends the chain. The indentation shows the depth of the inference.

**Built-in comparison**: `sibling(ann, bob)` incorporates an inequality check:
```
├─ sibling(ann,bob)
   ├─ parent(mary,ann)
      ✓ true
   ├─ parent(mary,bob)
      ✓ true
   ├─ ann\=bob
      ✓ ann\=bob
```
The final subgoal `ann \= bob` is printed as a leaf showing the built-in comparison. Without this check, the sibling rule would also report that Ann is her own sibling (since `parent(mary, ann)` and `parent(mary, ann)` would both succeed).

**Negation-as-failure** like `cousin(carol, emma)` uses `\+ sibling(carol, emma)`:
```
├─ cousin(carol,emma)
   ├─ grandparent(mary,carol)
      ├─ parent(mary,ann)
         ✓ true
      ├─ parent(ann,carol)
         ✓ true
   ├─ grandparent(mary,emma)
      ├─ parent(mary,bob)
         ✓ true
      ├─ parent(bob,emma)
         ✓ true
   ├─ carol\=emma
      ✓ carol\=emma
   ├─ \+sibling(carol,emma)
      ✓ \+sibling(carol,emma)
```
Carol and Emma share grandmother Mary, so they are cousins, unless they are also siblings. The `\+ sibling/2` goal checks that they are not, and the tree shows the check as a leaf. (The query has a second proof: Tom is also a grandparent of both, so backtracking gives another tree.)

**Derived predicates** like `aunt_uncle(michael, ann)` chains two relationships:
```
├─ aunt_uncle(michael,ann)
   ├─ parent(mary,ann)
      ✓ true
   ├─ sibling(michael,mary)
      ├─ parent(john,michael)
         ✓ true
      ├─ parent(john,mary)
         ✓ true
      ├─ michael\=mary
         ✓ michael\=mary
```
Michael is Ann's uncle because he is a sibling of Ann's parent Mary (they share their father, John). The tree shows both stages: Mary is Ann's parent, and Michael and Mary are siblings.

**Inverse relationships**: `descendant(grace, adam)` uses `ancestor/2` in reverse:
```
├─ descendant(grace,adam)
   ├─ ancestor(adam,grace)
      ├─ parent(adam,john)
         ✓ true
      ├─ ancestor(john,grace)
         ├─ parent(john,mary)
            ✓ true
         ├─ ancestor(mary,grace)
            ├─ parent(mary,ann)
               ✓ true
            ├─ ancestor(ann,grace)
               ├─ parent(ann,carol)
                  ✓ true
               ├─ ancestor(carol,grace)
                  ├─ parent(carol,grace)
                     ✓ true
```
The `descendant/2` rule is one clause, `descendant(X, Y) :- ancestor(Y, X)`, and the tree shows the whole ancestor chain behind it.

### Why Proof Trees Matter

Proof trees turn inference into explanations people can read. In an expert system, they let a domain expert check that conclusions follow from the intended rules. In legal or regulatory work, they are an audit trail. In an assistant, they answer "why did you conclude that?". And a proof tree is not an explanation made up after the fact: it *is* the reasoning, recorded as it happened.

## Bounded Reasoning

Prolog's depth-first search has a weak spot: if a predicate can produce an endless chain of goals, through a faulty recursive rule or through cyclic data, Prolog descends until it runs out of stack. In data gathered from the web, cycles are normal, not bugs. A person works for a division of a company, which owns a subsidiary, which employs the same person. Unchecked recursion over such data never ends.

The bounded meta-interpreter adds a depth counter that drops by one at each rule application. When it reaches zero, that branch is cut off. Each level has finitely many clauses to try, so the search is finite: `mi_bounded(Goal, MaxDepth)` always terminates, unless a built-in it calls does not.

Here is the file **meta_interp/prolog/bounded.pl**:

```prolog
:- module(bounded, [
    mi_bounded/2,
    mi_bounded/3
]).

%% mi_bounded(+Goal, +MaxDepth) - Solve with depth limit (user module)
mi_bounded(Goal, MaxDepth) :- mi_bounded(user, Goal, MaxDepth).

%% mi_bounded(+Module, +Goal, +MaxDepth)
%% Solve with depth limit and module context
mi_bounded(_, true, _) :- !.
mi_bounded(_, _, D) :- D =< 0, !, fail.
mi_bounded(Mod, (A, B), D) :- !,
    mi_bounded(Mod, A, D),
    mi_bounded(Mod, B, D).
mi_bounded(Mod, Goal, _) :-
    predicate_property(Mod:Goal, built_in), !,
    call(Mod:Goal).
mi_bounded(Mod, Goal, D) :-
    D > 0,
    clause(Mod:Goal, Body),
    D1 is D - 1,
    mi_bounded(Mod, Body, D1).
```

The limit is on the depth of the *proof tree*, not on the length of a chain of goals. Each rule application uses one unit, and the goals in a conjunction share their parent's remaining budget. Proving `grandparent(tom, ann)` uses one unit for the `grandparent/2` rule and one more for each `parent/2` fact below it, so it needs a depth of 2. A depth of 1 proves only facts. Each extra unit allows one more level of rules. For knowledge graph queries, `MaxDepth` bounds the path length you are willing to search.

**Iterative deepening** runs the bounded interpreter with limits 1, 2, 3, and so on, as in the Search Algorithms chapter. The first proof it finds has the smallest depth, and the search uses little memory. The loop lives in the caller, not in the interpreter.

## Reasoning with Uncertainty

In plain logic programming, a goal is proved or not. Many tasks need degrees of belief: a diagnosis system should say how likely a condition is, and a fraud detector should give a score, not a yes or no.

A meta-interpreter can compute a certainty for each conclusion as it proves it, combining the certainties of the sub-proofs. The rules stay ordinary logic; only the interpreter knows about certainty.

In the classic *certainty factor* approach, from the MYCIN expert system, each rule has a certainty between 0.0 and 1.0. Here is **meta_interp/prolog/certainty.pl**:

```prolog
%% certainty.pl - A meta-interpreter that computes certainty factors
%%
%% Rules are written as cf_rule(Head, Body, CF) facts, where CF is
%% between 0.0 and 1.0. The interpreter proves a goal and computes
%% how certain the conclusion is:
%%   - a conjunction is as certain as its weakest part (min)
%%   - a rule multiplies its own CF by the CF of its body
%%   - when several proofs exist, the best one counts (max)
:- module(certainty, [
    mi_cf/3,
    best_cf/3
]).

%% mi_cf(+Module, +Goal, -CF)
%% One proof of Goal and its certainty. Backtracking gives others.
mi_cf(_, true, 1.0) :- !.
mi_cf(Mod, (A, B), CF) :- !,
    mi_cf(Mod, A, CF1),
    mi_cf(Mod, B, CF2),
    CF is min(CF1, CF2).
mi_cf(Mod, Goal, 1.0) :-
    predicate_property(Mod:Goal, built_in), !,
    call(Mod:Goal).
mi_cf(Mod, Goal, CF) :-
    Mod:cf_rule(Goal, Body, RuleCF),
    mi_cf(Mod, Body, BodyCF),
    CF is RuleCF * BodyCF.

%% best_cf(+Module, +Goal, -CF)
%% The highest certainty over all proofs of Goal. Fails if Goal has
%% no proof.
best_cf(Mod, Goal, CF) :-
    aggregate_all(max(C), mi_cf(Mod, Goal, C), CF),
    CF \== -inf.
```

Here are the rules it runs on, from **meta_interp/prolog/sample_kb.pl**:

```prolog
%% Rules with certainty factors for mi_cf/3.
cf_rule(fever, true, 0.9).
cf_rule(cough, true, 0.6).
cf_rule(rash, true, 0.3).
cf_rule(flu, (fever, cough), 0.8).
cf_rule(measles, (fever, rash), 0.9).
cf_rule(see_doctor, flu, 0.7).
cf_rule(see_doctor, measles, 1.0).
```

For `see_doctor` there are two proofs. Through flu: `0.7 \times 0.8 \times \min(0.9, 0.6) = 0.336`$. Through measles: `1.0 \times 0.9 \times \min(0.9, 0.3) = 0.27`$. `best_cf/3` keeps the larger:

```prolog
?- best_cf(sample_kb, see_doctor, CF).
CF = 0.33599999999999997.
```

A conjunction gets the `min` of its parts, since reasoning is only as strong as its weakest step. A rule multiplies its own certainty by its body's. Other choices give other models: fuzzy logic uses `min` and `max`, probability uses products under independence, and Dempster-Shafer theory uses intervals.

The rules say *what* is true and the numbers say *how sure* we are. To try another model of uncertainty, you change only the interpreter. MYCIN itself combined two proofs of the same conclusion with `CF_1 + CF_2 (1 - CF_1)`$ rather than `max`, so that independent evidence adds up; practice problem 2 asks you to try that.

## Custom Search Strategies

Prolog's depth-first, left-to-right search is fast and predictable, but not always what you want. A puzzle solver may want breadth-first search for the shortest solution, a theorem prover iterative deepening for completeness, and a planner best-first search guided by a heuristic.

A meta-interpreter can change the search strategy without changing the rules. Instead of letting Prolog's backtracking drive the search, it keeps its own queue of alternatives. The hard part is variable bindings: each alternative branch binds variables differently, so each queue entry needs its own copy. Here is **meta_interp/prolog/bfs.pl**:

```prolog
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
```

Each queue entry is a whole search state: the list of goals left to prove (the *resolvent*) and a copy of the original goal, `Answer`, that shows how this branch has bound its variables. `findall/3` makes copies, so the states never share variables. When a resolvent becomes empty, its `Answer` is a solution. A simpler design that puts single goals on the queue does not work: it loses track of which goals belong to the same proof, and it can report success when only one part of a conjunction holds.

The sample knowledge base has a cyclic graph and a *left-recursive* `path/2`:

```prolog
%% A graph with a cycle, and a LEFT-recursive path/2. Plain Prolog
%% loops forever on path(a, X); mi_bfs/3 does not.
edge(a, b).
edge(b, c).
edge(c, a).
edge(c, d).

path(X, Y) :- path(X, Z), edge(Z, Y).
path(X, Y) :- edge(X, Y).
```

Plain Prolog never answers `path(a, X)`: it calls `path(a, Z)` again before checking any edge, forever. The breadth-first interpreter finds every reachable node, shortest paths first:

```prolog
?- findall(X, mi_bfs(sample_kb, path(a, X), 1000), Xs).
Xs = [b, c, a, d, b, c, a, d, ...].
```

The answers repeat because the cycle gives longer and longer paths to the same nodes: with a limit of 1,000 states, the query returns 24 answers. `MaxStates` stops the search; without it, a query with no answer, such as `path(d, a)`, would run forever. Breadth-first search finds every answer that has a proof, but it cannot tell you that no proof exists.

Other strategies change only how the queue is ordered. For **best-first search**, sort the queue by a heuristic score. For **beam search**, keep only the best *k* states. The rules stay the same.

This separates the *logic* of a program (what is true) from its *control* (how to find it). Robert Kowalski summed this up as "Algorithm = Logic + Control", and a meta-interpreter is where the control lives.

## Debugging and Tracing Meta-Interpreters

Prolog's built-in tracer (`trace/0`) shows every port (Call, Exit, Redo, Fail) of every goal, which quickly becomes too much. A tracer written as a meta-interpreter can show only what you care about. Here is **meta_interp/prolog/tracer.pl**:

```prolog
%% tracer.pl - A meta-interpreter that prints a structured trace
:- module(tracer, [
    mi_trace/1,
    mi_trace/2
]).

%% mi_trace(+Goal)
%% mi_trace(+Module, +Goal)
%% Solve Goal like Prolog does, printing CALL, EXIT, and FAIL lines
%% indented by depth. Built-in goals are shown on one line.
mi_trace(Goal) :-
    mi_trace(user, Goal).

mi_trace(Mod, Goal) :-
    trace_goal(Mod, Goal, 0).

trace_goal(_, true, _) :- !.
trace_goal(Mod, (A, B), D) :- !,
    trace_goal(Mod, A, D),
    trace_goal(Mod, B, D).
trace_goal(Mod, G, D) :-
    predicate_property(Mod:G, built_in), !,
    (   call(Mod:G)
    ->  report(D, 'BUILTIN', G)
    ;   report(D, 'FAIL', G),
        fail
    ).
trace_goal(Mod, G, D) :-
    report(D, 'CALL', G),
    D1 is D + 1,
    (   clause(Mod:G, Body),
        trace_goal(Mod, Body, D1),
        report(D, 'EXIT', G)
    ;   report(D, 'FAIL', G),
        fail
    ).

report(Depth, Port, Goal) :-
    Indent is Depth * 2,
    format("~t~*|~w ~p~n", [Indent, Port, Goal]).
```

`trace_goal/3` prints `CALL` before trying a goal's clauses and `EXIT` after one succeeds. The disjunction `( ... ; report(D, 'FAIL', G), fail )` prints `FAIL` once every clause has been tried, and the final `fail` passes the failure on. Built-ins print on one line. Here is a failing query:

```text
?- mi_trace(sample_kb, older(bob, tom)).
CALL older(bob,tom)
  CALL age(bob,_)
  EXIT age(bob,45)
  CALL age(tom,_)
  EXIT age(tom,70)
  FAIL 45>70
  FAIL age(tom,_)
  FAIL age(bob,_)
FAIL older(bob,tom)
false.
```

The trace shows the failed comparison and then each goal failing in turn as backtracking finds no other clause.

The same approach can count inference steps, time each predicate, or record which rules each conclusion used. Because this lives in the interpreter, you can turn it on for one query without changing the knowledge base.

A more advanced use is **declarative debugging** (also called algorithmic debugging), from Ehud Shapiro's work. When a query gives a wrong answer, the debugger walks the proof tree and asks you whether each intermediate conclusion is correct, and so finds the clause that is wrong. Each answer rules out a whole subtree, so it needs far fewer steps than stepping through the execution.

## Summary

Meta-interpreters let you program how Prolog reasons. Starting from the four-clause vanilla interpreter, we added proof trees for explanations, depth bounds for termination, certainty factors for uncertainty, a queue for breadth-first search, and a tracer for debugging. Each is a small change, and none changes the knowledge base.

The `meta_interp` and `proof_trees` projects contain all of them, with tests. `make run` in `meta_interp` shows each one on the sample knowledge base.

## Optional Practice Problems

1. **Counting Steps**: Write `mi_count(+Mod, +Goal, -Steps)`, a vanilla interpreter that also returns the number of rule applications in the proof. Compare `grandparent(tom, ann)` and `ancestor(adam, grace)` from the proof tree data.
2. **MYCIN Combination**: Change `best_cf/3` to combine two proofs with `CF_1 + CF_2 (1 - CF_1)`$ instead of `max`. What is the certainty of `see_doctor` now?
3. **Iterative Deepening**: Write `mi_iddfs(+Mod, +Goal, +MaxDepth)` that calls `mi_bounded/3` with depths 1, 2, ... up to `MaxDepth`. Does it answer `path(a, X)` on the sample graph? Why, given that `path/2` is left-recursive?
