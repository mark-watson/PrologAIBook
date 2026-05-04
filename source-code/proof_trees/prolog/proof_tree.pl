%% proof_tree.pl - Build and display proof trees for explainable reasoning
:- module(proof_tree, [
    prove_with_tree/2,
    print_proof/1
]).

%% prove_with_tree(+Goal, -Tree) - Prove and return proof tree
prove_with_tree(true, leaf(true)) :- !.
prove_with_tree((A, B), and(PA, PB)) :- !,
    prove_with_tree(A, PA),
    prove_with_tree(B, PB).
prove_with_tree(Goal, node(Goal, ChildProofs)) :-
    clause(Goal, Body),
    prove_with_tree(Body, ChildProofs).

%% print_proof(+Tree) - Pretty-print a proof tree with indentation
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
