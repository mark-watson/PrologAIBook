%% rdfs_reason.pl - RDFS type inference, including domain and range
:- module(rdfs_reason, [
    instance_of/2,
    types_of/2
]).

:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdfs)).

:- rdf_meta
    instance_of(r, r),
    types_of(r, -).

%% instance_of(?Resource, ?Class)
%% Resource is an instance of Class under these RDFS rules:
%%   - an rdf:type triple, up the rdfs:subClassOf hierarchy
%%     (library(semweb/rdfs) handles this case)
%%   - Resource is the subject of a property whose rdfs:domain is
%%     Class or a subclass of it
%%   - Resource is the object of a property whose rdfs:range is
%%     Class or a subclass of it
%% May give the same answer more than once; types_of/2 removes
%% duplicates.
instance_of(Resource, Class) :-
    rdfs_individual_of(Resource, Class).
instance_of(Resource, Class) :-
    rdf(Resource, P, _),
    rdf(P, rdfs:domain, Domain),
    rdfs_subclass_of(Domain, Class).
instance_of(Resource, Class) :-
    rdf(_, P, Resource),
    atom(Resource),                % literals have no class
    rdf(P, rdfs:range, Range),
    rdfs_subclass_of(Range, Class).

%% types_of(+Resource, -Classes)
%% Sorted list of every class Resource belongs to.
types_of(Resource, Classes) :-
    (   setof(C, instance_of(Resource, C), Classes)
    ->  true
    ;   Classes = []
    ).
