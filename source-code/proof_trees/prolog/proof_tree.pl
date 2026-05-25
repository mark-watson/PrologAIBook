%% proof_tree.pl - Build and display proof trees
%% for explainable reasoning
:- module(proof_tree, [
    prove_with_tree/2,
    print_proof/1,
    sample_data_loaded/0
]).

%% Load sample data - try multiple paths for
%% different working directories
sample_data_loaded :-
    (   exists_file('sample_data.pl')
    ->  consult('sample_data.pl')
    ;   exists_file('prolog/sample_data.pl')
    ->  consult('prolog/sample_data.pl')
    ;   format(user_error, 'WARNING: sample_data.pl not found~n', []),
        fail
    ).

:- initialization(sample_data_loaded).

%% prove_with_tree(+Goal, -Tree) - Prove and return proof tree
prove_with_tree(true, leaf(true)) :- !.
prove_with_tree((A, B), and(PA, PB)) :- !,
    prove_with_tree(A, PA),
    prove_with_tree(B, PB).
%% Handle negation-as-failure (meta-builtin)
prove_with_tree(\+ G, node(\+ G, leaf(\+ G))) :- !,
    \+ G.
%% Handle not-unifiable (builtin comparison)
prove_with_tree(X \= Y, node(X\=Y, leaf(X\=Y))) :- !,
    X \= Y.
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
