:- module(test_rdf, []).
:- use_module(library(plunit)).
:- use_module(library(semweb/rdf_db)).
:- use_module('../prolog/rdf_loader').
:- use_module('../prolog/rdfs_reason').

:- rdf_register_prefix(ex, 'http://example.org/').

load_and_setup :-
    source_file(load_and_setup, File),
    file_directory_name(File, Dir),
    atomic_list_concat([Dir, '/../example.ttl'], Rel),
    absolute_file_name(Rel, Abs),
    load_rdf_file(Abs).

:- load_and_setup.

:- begin_tests(rdf_loader).

test(load_and_query) :-
    query_rdf(S, 'http://www.w3.org/2000/01/rdf-schema#label',
              literal('SWI-Prolog')),
    assertion(S == 'http://example.org/swi_prolog').

test(subjects_returns_list) :-
    subjects(Subjects),
    assertion(memberchk('http://example.org/prolog', Subjects)),
    assertion(memberchk('http://example.org/swi_prolog', Subjects)).

test(triples_of_returns_data) :-
    triples_of('http://example.org/swi_prolog', Triples),
    assertion(memberchk('http://www.w3.org/2000/01/rdf-schema#label'
                        -literal('SWI-Prolog'), Triples)).

:- end_tests(rdf_loader).

:- begin_tests(rdfs_reason).

test(subclass_inference) :-
    instance_of(ex:swi_prolog, ex:'Software'), !.

test(domain_inference) :-
    % scryer_prolog has no rdf:type; the domain of ex:implements
    % makes it an Implementation, and so Software.
    types_of(ex:scryer_prolog, Types),
    rdf_global_id(ex:'Implementation', Impl),
    rdf_global_id(ex:'Software', Soft),
    assertion(memberchk(Impl, Types)),
    assertion(memberchk(Soft, Types)).

test(range_inference) :-
    rdf_global_id(ex:'Notation', Notation),
    types_of(ex:prolog, Types),
    assertion(memberchk(Notation, Types)).

test(no_type_from_property_value, [fail]) :-
    % prolog's paradigm is LogicProgramming, but that does not make
    % prolog an instance of LogicProgramming.
    instance_of(ex:prolog, ex:'LogicProgramming').

:- end_tests(rdfs_reason).

cleanup_rdf :- rdf_db:rdf_reset_db.
:- at_halt(cleanup_rdf).
