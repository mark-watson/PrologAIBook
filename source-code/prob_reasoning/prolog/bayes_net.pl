%% bayes_net.pl - Exact inference in a small Bayesian network by
%% enumerating all possible worlds.
:- module(bayes_net, [
    prob/3,
    joint/2,
    world/1
]).

%% Network structure: parent(ParentNode, ChildNode)
parent(cloudy, rain).
parent(cloudy, sprinkler).
parent(rain, wet_grass).
parent(sprinkler, wet_grass).

%% CPT entries: cpt(Node, true, ParentStates, Probability)
%% gives P(Node = true | ParentStates). P(Node = false | ...) is
%% 1 minus that value.
cpt(cloudy, true, [], 0.5).
cpt(sprinkler, true, [cloudy=true], 0.1).
cpt(sprinkler, true, [cloudy=false], 0.5).
cpt(rain, true, [cloudy=true], 0.8).
cpt(rain, true, [cloudy=false], 0.2).
cpt(wet_grass, true, [sprinkler=true, rain=true], 0.99).
cpt(wet_grass, true, [sprinkler=true, rain=false], 0.90).
cpt(wet_grass, true, [sprinkler=false, rain=true], 0.90).
cpt(wet_grass, true, [sprinkler=false, rain=false], 0.01).

%% The network's variables. Every node appears in some cpt/4 fact.
variables(Vars) :-
    findall(V, cpt(V, _, _, _), Vs),
    sort(Vs, Vars).

%% world(-World)
%% World is a list Var=Value giving every variable a value. On
%% backtracking it enumerates all 2^N worlds.
world(World) :-
    variables(Vars),
    maplist(assign, Vars, World).

assign(Var, Var=Value) :-
    member(Value, [true, false]).

%% joint(+World, -P)
%% The probability of a complete world: the product of
%% P(node | parents) over all nodes (the chain rule for Bayes nets).
joint(World, P) :-
    foldl(node_factor(World), World, 1.0, P).

node_factor(World, Node=Value, P0, P) :-
    cpt(Node, true, ParentStates, PTrue),
    subset(ParentStates, World),
    !,
    (   Value == true
    ->  P is P0 * PTrue
    ;   P is P0 * (1 - PTrue)
    ).

%% prob(+Query, +Evidence, -P)
%% P is P(Query | Evidence), where Query and Evidence are lists of
%% Var=Value. We sum the joint probability of the worlds where
%% Query and Evidence hold, and divide by the sum over the worlds
%% where Evidence holds.
prob(Query, Evidence, P) :-
    append(Query, Evidence, Both),
    mass(Both, PBoth),
    mass(Evidence, PEvidence),
    PEvidence > 0,
    P is PBoth / PEvidence.

%% mass(+Partial, -P): total probability of the worlds that agree
%% with the partial assignment Partial.
mass(Partial, P) :-
    aggregate_all(sum(PW),
                  ( world(W), subset(Partial, W), joint(W, PW) ),
                  P).
