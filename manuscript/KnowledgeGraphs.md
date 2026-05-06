# Knowledge Graphs and Knowledge Representation

Knowledge representation is at the heart of symbolic AI, and Prolog's fact-and-rule database is itself a knowledge representation system. In this chapter we build tools for creating, querying, and reasoning over knowledge graphs — a topic the author has explored extensively in Common Lisp, Haskell, and other languages.

{width: "80%"}
![Architecture diagram for the Knowledge Graph Creator example](FIG_kg_creator.jpg)

{width: "80%"}
![Architecture diagram for the Knowledge Graph Query example](FIG_kg_query.jpg)

## Representing Knowledge in Prolog

TBD: Using Prolog's database as a knowledge base. Facts as triples (subject, predicate, object). Organizing knowledge with modules.

## Building a Knowledge Graph from Text

TBD: Automatically extracting entities and relationships from unstructured text using the NLP techniques from earlier chapters, and storing them as Prolog facts. Inspired by the author's KGCreator project.

The **kg_creator** project stores knowledge as dynamic triple facts. Here is the file **kg_creator/prolog/kg_builder.pl**:

```prolog
%% kg_builder.pl - Build knowledge graphs and store as Prolog facts
:- module(kg_builder, [
    add_triple/3, query_triples/3,
    export_rdf/1, export_cypher/1
]).

:- dynamic triple/3.  % triple(Subject, Predicate, Object)

%% add_triple(+S, +P, +O) - Add a triple if not already present
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
        (   forall(triple(S, P, O),
                format(Stream, '<~w> <~w> "~w" .~n', [S, P, O]))
        ),
        close(Stream)
    ).

%% export_cypher(+FileName) - Export as Neo4j Cypher statements
export_cypher(FileName) :-
    setup_call_cleanup(
        open(FileName, write, Stream),
        (   forall(triple(S, P, O),
                format(Stream, 'CREATE (~w)-[:~w]->(~w)~n', [S, P, O]))
        ),
        close(Stream)
    ).
```

## Querying Knowledge Graphs

TBD: Writing Prolog queries to traverse and interrogate knowledge graphs. Multi-hop reasoning across relationships.

The **kg_query** project implements multi-hop reasoning over knowledge graphs. Here is the file **kg_query/prolog/kg_reason.pl**:

```prolog
%% kg_reason.pl - Multi-hop reasoning over knowledge graphs
:- module(kg_reason, [
    entity/2, relation/3, path/3, connected/2
]).

:- dynamic entity/2.      % entity(ID, Type)
:- dynamic relation/3.    % relation(From, Predicate, To)

%% path(+Start, +End, -Path) - Find multi-hop path
path(Start, End, [Start, End]) :-
    relation(Start, _, End).
path(Start, End, [Start|Rest]) :-
    relation(Start, _, Mid),
    Mid \= End,
    path(Mid, End, Rest).

%% connected(+A, +B) - Are two entities connected by any path?
connected(A, B) :- path(A, B, _).
connected(A, B) :- path(B, A, _).

%% Example knowledge graph
:- assert(entity(mark, person)).
:- assert(entity(prolog, language)).
:- assert(entity(ai, field)).
:- assert(entity(swi, implementation)).
:- assert(relation(mark, writes_about, ai)).
:- assert(relation(mark, uses, prolog)).
:- assert(relation(prolog, implemented_by, swi)).
:- assert(relation(ai, uses, prolog)).
```

## Generating RDF and Neo4j Cypher Data from Prolog

TBD: Exporting Prolog knowledge bases to RDF N-Triples format and Neo4j Cypher format for interoperability with graph database systems.

## Integrating with DBpedia and Wikidata

TBD: Enriching local knowledge graphs with data from public linked data sources using SPARQL queries from Prolog.
