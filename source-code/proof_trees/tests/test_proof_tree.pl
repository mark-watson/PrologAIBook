:- module(test_proof_tree, []).
:- use_module(library(plunit)).
:- use_module('../prolog/proof_tree').

:- begin_tests(proof_tree).

test(module_loads) :-
    true.

test(simple_fact, [true(Tree == node(parent(adam,john), leaf(true)))]) :-
    prove_with_tree(parent(adam, john), Tree).

test(conjunction_grandparent, [
    true(Tree == node(grandparent(john,ann),
        and(node(parent(john,mary), leaf(true)),
            node(parent(mary,ann), leaf(true)))))
]) :-
    once(prove_with_tree(grandparent(john, ann), Tree)).

test(recursive_ancestor_direct, [
    true(Tree == node(ancestor(mary,ann),
        node(parent(mary,ann), leaf(true))))
]) :-
    once(prove_with_tree(ancestor(mary, ann), Tree)).

test(recursive_ancestor_multi_step, [
    true(Tree == node(ancestor(adam,mary),
        and(node(parent(adam,john), leaf(true)),
            node(ancestor(john,mary),
                node(parent(john,mary), leaf(true))))))
]) :-
    once(prove_with_tree(ancestor(adam, mary), Tree)).

test(sibling_with_builtin) :-
    once(prove_with_tree(sibling(ann, bob), Tree)),
    Tree = node(sibling(ann,bob), and(
        node(parent(mary,ann), leaf(true)),
        and(node(parent(mary,bob), leaf(true)),
            node(ann\=bob, leaf(ann\=bob))))).

test(cousin_multi_step) :-
    once(prove_with_tree(cousin(carol, emma), _Tree)).

test(great_grandparent_chain) :-
    once(prove_with_tree(great_grandparent(adam, ann), _Tree)).

test(aunt_uncle_derived) :-
    once(prove_with_tree(aunt_uncle(michael, ann), _Tree)).

test(descendant_uses_ancestor) :-
    once(prove_with_tree(descendant(grace, adam), _Tree)).

test(print_proof_does_not_throw) :-
    once(prove_with_tree(grandparent(john, ann), Tree)),
    with_output_to(atom(_), print_proof(Tree)).

test(true_goal, [true(Tree == leaf(true))]) :-
    prove_with_tree(true, Tree).

test(negation_builtin_leaf) :-
    prove_with_tree(\+ parent(adam, ann), Tree),
    Tree = node(\+ parent(adam,ann), leaf(\+ parent(adam,ann))).

test(not_unifiable_builtin_leaf) :-
    prove_with_tree(ann \= bob, Tree),
    Tree = node(ann\=bob, leaf(ann\=bob)).

:- end_tests(proof_tree).