%% kg_builder.pl - Build knowledge graphs from
%% text and store as Prolog facts
:- module(kg_builder, [
    add_triple/3,
    query_triples/3,
    export_rdf/1,
    export_cypher/1
]).

:- dynamic triple/3.  % triple(Subject, Predicate, Object)

%% add_triple(+S, +P, +O)
%% Add a triple if not already present (always succeeds)
add_triple(S, P, O) :-
    (   triple(S, P, O)
    ->  true
    ;   assert(triple(S, P, O))
    ).

%% query_triples(?S, ?P, ?O)
query_triples(S, P, O) :- triple(S, P, O).

%% export_rdf(+FileName) - Export triples as N-Triples RDF
export_rdf(FileName) :-
    setup_call_cleanup(
        open(FileName, write, Stream),
        (   forall(
                triple(S, P, O),
                format(Stream, '<~w> <~w> "~w" .~n', [S, P, O])
            )
        ),
        close(Stream)
    ).

%% export_cypher(+FileName)
%% Export triples as Neo4j Cypher CREATE statements
export_cypher(FileName) :-
    setup_call_cleanup(
        open(FileName, write, Stream),
        (   forall(
                triple(S, P, O),
                format(Stream, 'CREATE (~w)-[:~w]->(~w)~n', [S, P, O])
            )
        ),
        close(Stream)
    ).
