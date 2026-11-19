%% proof_tree.pl - Build and display proof trees
%% for explainable reasoning
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
