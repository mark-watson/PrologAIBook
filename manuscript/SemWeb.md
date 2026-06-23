# Semantic Web Tools

Prolog's logic-based foundation makes it a natural fit for working with Semantic Web technologies — RDF, RDFS, OWL, and SPARQL. SWI-Prolog provides mature libraries for all of these.

## Loading and Querying RDF Data

The Resource Description Framework (RDF) represents knowledge as a directed graph of subject-predicate-object triples. SWI-Prolog includes a highly optimized RDF database in its `semweb` library package.

### The Turtle Format

While RDF can be serialized in XML (RDF/XML) or JSON (JSON-LD), the **Turtle** (Terse RDF Triple Language) format is the standard, human-readable serialization. In Turtle, triples are declared as space-separated terms ending with a period:

```turtle
@prefix ex: <http://example.org/> .
ex:swi_prolog ex:implements ex:prolog .
```

You can group multiple statements about the same subject using a semicolon (`;`) or comma (`,`):

```turtle
ex:prolog a ex:Language ;
    rdfs:label "Prolog" ;
    ex:paradigm ex:LogicProgramming .
```

### Loading and Querying in Prolog

The `library(semweb/rdf_db)` module stores all loaded RDF triples in an internal database, which we query using `rdf(?Subject, ?Predicate, ?Object)`. To parse Turtle files, we import `library(semweb/turtle)`.


{width: "80%"}
![Architecture diagram for the RDF Explorer example](FIG_rdf_explorer.jpg)

The **rdf_explorer** project wraps SWI-Prolog's semweb library. Here is the complete file **rdf_explorer/prolog/rdf_loader.pl**:

```prolog
%% rdf_loader.pl - Load and query RDF data using SWI-Prolog's semweb
%% library
:- module(rdf_loader, [
    load_rdf_file/1,
    query_rdf/3,
    list_subjects/0,
    describe_resource/1
]).

:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdfs)).
:- use_module(library(semweb/turtle)).

%% load_rdf_file(+FilePath) - Load RDF from Turtle or RDF/XML file
load_rdf_file(FilePath) :-
    rdf_load(FilePath).

%% query_rdf(?S, ?P, ?O) - Query the RDF triplestore
query_rdf(S, P, O) :- rdf(S, P, O).

%% list_subjects - Print all unique subjects
list_subjects :-
    setof(S, P^O^rdf(S, P, O), Subjects),
    forall(member(S, Subjects), format("  ~w~n", [S])).

%% describe_resource(+URI) - Print all triples for a given subject
describe_resource(URI) :-
    format("Describing: ~w~n", [URI]),
    forall(
        rdf(URI, P, O),
        format("  ~w -> ~w~n", [P, O])
    ).
```

## Querying Remote SPARQL Endpoints

To query RDF data across the web, we use **SPARQL** (SPARQL Protocol and RDF Query Language). SWI-Prolog provides a standard SPARQL client in `library(semweb/sparql_client)`. This module sends a SPARQL SELECT query over HTTP to a remote endpoint and parses the returned JSON or XML results into Prolog terms.

A SPARQL query typically specifies variables starting with a question mark (e.g. `?developer`). The result of a query is returned as individual `row(Value1, Value2, ...)` terms containing the unified results for each row.

{width: "80%"}
![Architecture diagram for the SPARQL Client example](FIG_sparql_client.jpg)

The **sparql_client** project provides convenient wrappers for sending queries. Here is the complete file **sparql_client/prolog/sparql.pl**:

```prolog
%% sparql.pl - SPARQL client for querying remote endpoints
:- module(sparql, [
    sparql_query_dbpedia/2,
    sparql_query_wikidata/2,
    sparql_query/3
]).

:- use_module(library(semweb/sparql_client)).
:- use_module(library(http/http_client)).

%% sparql_query_dbpedia(+Query, -Results)
sparql_query_dbpedia(Query, Results) :-
    sparql_query(Query, Results,
                 [host('dbpedia.org'), path('/sparql')]).

%% sparql_query_wikidata(+Query, -Results)
sparql_query_wikidata(Query, Results) :-
    sparql_query(Query, Results,
                 [host('query.wikidata.org'), path('/sparql')]).
```

## RDFS and OWL Reasoning

Standard RDF only represents direct relationships. To perform semantic reasoning, we use **RDF Schema (RDFS)** and the **Web Ontology Language (OWL)**. RDFS introduces properties like:
- `rdfs:subClassOf`: Declares hierarchical class inheritance.
- `rdfs:subPropertyOf`: Declares subproperty inheritance.
- `rdfs:domain` / `rdfs:range`: Restricts the types of subjects and objects a property can link.

Prolog is well-suited to reason over these rules, but SWI-Prolog's `library(semweb/rdfs)` implements them directly in highly optimized C-level hooks, saving you from writing recursive rules yourself.

The most important predicates are:

- **`rdfs_individual_of(?Resource, ?Class)`**: Succeeds if `Resource` is an instance of `Class`, resolving any transitive class inheritance (via `subClassOf`) and property domains/ranges.
- **`rdfs_subclass_of(?SubClass, ?SuperClass)`**: True if `SubClass` is a subclass of `SuperClass` (either directly or transitively).
- **`rdfs_subproperty_of(?SubProperty, ?SuperProperty)`**: True if `SubProperty` inherits from `SuperProperty`.

For example, if we load an ontology stating that `ex:LogicProgramming` is a subclass of `ex:ProgrammingParadigm`, and `ex:prolog` has paradigm `ex:LogicProgramming`, the standard `rdf/3` query won't show that Prolog is a `ProgrammingParadigm`. However, RDFS reasoning unifies it immediately:

```prolog
?- rdfs_individual_of('http://example.org/prolog', 'http://example.org/ProgrammingParadigm').
true.
```

## Practical Applications

You can combine local RDF data with remote SPARQL queries to build a **domain-specific knowledge explorer**. This hybrid architecture allows you to maintain private, local triples (such as proprietary client records or local system settings) while enriching them dynamically with global, public information from Wikidata or DBpedia.

Here is a Prolog module showing this pattern:

```prolog
:- module(knowledge_explorer, [
    explore_and_enrich/1
]).

:- use_module(library(semweb/rdf_db)).
:- use_module(sparql_client/prolog/sparql).

%% explore_and_enrich(+ResourceURI)
%% 1. Find and print all local facts about the resource.
%% 2. Query DBpedia to fetch the English abstract/description.
explore_and_enrich(ResourceURI) :-
    format("=== Local Knowledge for ~w ===~n", [ResourceURI]),
    forall(
        rdf(ResourceURI, P, O),
        format("  Local: ~w -> ~w~n", [P, O])
    ),
    
    % Extract the local name from the URI to query DBpedia
    % e.g., 'http://example.org/Prolog' -> "Prolog"
    file_base_name(ResourceURI, LocalName),
    format("~n=== Querying DBpedia for ~w ===~n", [LocalName]),
    
    format(string(Query),
        "SELECT ?abstract WHERE { \n\
         <http://dbpedia.org/resource/~w> <http://dbpedia.org/ontology/abstract> ?abstract . \n\
         FILTER (lang(?abstract) = 'en') \n\
         } LIMIT 1", [LocalName]),
         
    (   catch(sparql_query_dbpedia(Query, row(literal(Abstract))), _, fail)
    ->  format("  Abstract: ~w~n", [Abstract])
    ;   writeln("  Could not fetch remote abstract.")
    ).
```

This pattern keeps your local codebase small and lightweight while placing the billions of triples of the Semantic Web at your logic engine's disposal.

## Optional Practice Problems

1. **Dbpedia SPARQL Query**: Modify `sparql_client` to fetch birth dates, death dates, and nationalities of famous computer scientists from the official DBpedia SPARQL endpoint.
2. **RDF Subject Search**: In the `rdf_explorer` project, write a predicate to find all predicates and objects associated with a specific subject URI, filtering out anonymous blank nodes.
