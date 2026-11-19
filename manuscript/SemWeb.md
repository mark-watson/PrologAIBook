# Semantic Web Tools

Prolog's logic foundation makes it a good fit for Semantic Web technologies: RDF, RDFS, OWL, and SPARQL. SWI-Prolog has mature libraries for all of them.

## Loading and Querying RDF Data

The Resource Description Framework (RDF) represents knowledge as a directed graph of subject-predicate-object triples. SWI-Prolog's `semweb` package includes a fast RDF database.

### The Turtle Format

RDF can be written as XML (RDF/XML) or JSON (JSON-LD), but **Turtle** (Terse RDF Triple Language) is the easiest to read. In Turtle, a triple is three terms ending with a period:

```turtle
@prefix ex: <http://example.org/> .
ex:swi_prolog ex:implements ex:prolog .
```

A semicolon (`;`) adds another predicate for the same subject, and a comma (`,`) adds another object for the same predicate. `a` is short for `rdf:type`:

```turtle
ex:prolog a ex:Language ;
    rdfs:label "Prolog" ;
    ex:paradigm ex:LogicProgramming .
```

### Loading and Querying in Prolog

`library(semweb/rdf_db)` stores loaded triples in an in-memory database, which we query with `rdf(?Subject, ?Predicate, ?Object)`. Loading `library(semweb/turtle)` lets `rdf_load/1` parse Turtle files.


{width: "80%"}
![Architecture diagram for the RDF Explorer example](FIG_rdf_explorer.jpg)

The **rdf_explorer** project wraps the semweb library. Here is the file **rdf_explorer/prolog/rdf_loader.pl**:

```prolog
%% rdf_loader.pl - Load and query RDF data using SWI-Prolog's semweb
%% library
:- module(rdf_loader, [
    load_rdf_file/1,
    query_rdf/3,
    list_subjects/0,
    describe_resource/1,
    subjects/1,
    triples_of/2
]).

:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/turtle)).

%% load_rdf_file(+FilePath) - Load RDF from Turtle or RDF/XML file
%% Relative paths are resolved against the calling source file's
%% directory when possible, so tests/examples are CWD-independent.
load_rdf_file(FilePath) :-
    (   absolute_file_name(FilePath, Abs, [access(read)])
    ->  true
    ;   prolog_load_context(source, Source),
        file_directory_name(Source, Dir),
        atomic_list_concat([Dir, '/', FilePath], Candidate),
        absolute_file_name(Candidate, Abs, [access(read)])
    ),
    rdf_load(Abs).

%% query_rdf(?S, ?P, ?O) - Query the RDF triplestore
query_rdf(S, P, O) :- rdf(S, P, O).

%% subjects(-Subjects) - Return the sorted list of unique subjects
subjects(Subjects) :-
    setof(S, P^O^rdf(S, P, O), Subjects).

%% triples_of(+URI, -Triples) - Return P-O pairs for a subject
triples_of(URI, Triples) :-
    findall(P-O, rdf(URI, P, O), Triples).

%% list_subjects - Print all unique subjects
list_subjects :-
    subjects(Subjects),
    forall(member(S, Subjects), format("  ~w~n", [S])).

%% describe_resource(+URI) - Print all triples for a given subject
describe_resource(URI) :-
    format("Describing: ~w~n", [URI]),
    triples_of(URI, Triples),
    forall(
        member(P-O, Triples),
        format("  ~w -> ~w~n", [P, O])
    ).
```

`subjects/1` and `triples_of/2` return data, and `list_subjects/0` and `describe_resource/1` print it. In a query, a literal comes back as a `literal(...)` term and a resource as an atom holding its IRI.

## Querying Remote SPARQL Endpoints

To query RDF data on the web we use **SPARQL** (SPARQL Protocol and RDF Query Language). `library(semweb/sparql_client)` sends a SPARQL query over HTTP to a remote endpoint and turns the results into Prolog terms.

SPARQL variables start with a question mark (e.g. `?developer`). `sparql_query/3` returns one `row(Value1, Value2, ...)` term per result, with one argument per selected variable, and backtracking gives the next row.

{width: "80%"}
![Architecture diagram for the SPARQL Client example](FIG_sparql_client.jpg)

The **sparql_client** project wraps the library for two public endpoints. Here is the file **sparql_client/prolog/sparql.pl**:

```prolog
%% sparql.pl - SPARQL client for querying remote endpoints
:- module(sparql, [
    sparql_query_dbpedia/2,
    wikidata_query/2,
    sparql_query/3,
    sparql_literal/2,
    sparql_iri/2
]).

:- use_module(library(semweb/sparql_client),
              [sparql_query/3 as sparql_client_query]).
:- use_module(library(http/http_open)).    % https support

%% sparql_query(+Query, -Row, +Options)
%% Thin wrapper over sparql_client:sparql_query/3 that adds a
%% 30-second timeout unless Options gives one. Backtracking yields one
%% row(...) term per result.
sparql_query(Query, Results, Options) :-
    (   memberchk(timeout(_), Options)
    ->  AllOptions = Options
    ;   AllOptions = [timeout(30)|Options]
    ),
    sparql_client_query(Query, Results, AllOptions).

%% sparql_query_dbpedia(+Query, -Row)
%% Query DBpedia's public endpoint. Each solution is one result row.
sparql_query_dbpedia(Query, Row) :-
    sparql_query(Query, Row,
                 [endpoint('https://dbpedia.org/sparql')]).

%% wikidata_query(+Query, -Row)
%% Query the Wikidata Query Service. Use full IRIs in the query; the
%% wd: and wdt: prefixes are predefined by the service, so they also
%% work.
wikidata_query(Query, Row) :-
    sparql_query(Query, Row,
                 [endpoint('https://query.wikidata.org/sparql')]).

%% sparql_literal(+Atom, -Quoted)
%% Safely quote an atom as a SPARQL string literal: backslashes and
%% double quotes are escaped, result wrapped in double quotes.
sparql_literal(Atom, Quoted) :-
    atom_string(Atom, Str),
    string_codes(Str, Codes),
    escape_literal_codes(Codes, EscapedCodes),
    string_codes(Escaped, EscapedCodes),
    format(atom(Quoted), '"~w"', [Escaped]).

escape_literal_codes([], []).
escape_literal_codes([0'\\|Cs], [0'\\,0'\\|Es]) :-
    !,
    escape_literal_codes(Cs, Es).
escape_literal_codes([0'"|Cs], [0'\\,0'"|Es]) :-
    !,
    escape_literal_codes(Cs, Es).
escape_literal_codes([C|Cs], [C|Es]) :-
    escape_literal_codes(Cs, Es).

%% sparql_iri(+Atom, -Quoted)
%% Wrap an atom as a SPARQL IRI reference: <...>.
sparql_iri(Atom, Quoted) :-
    format(atom(Quoted), '<~w>', [Atom]).
```

The local `sparql_query/3` adds a 30-second timeout unless the options set one. Give each endpoint as a full `https` URL with `endpoint(URL)`: DBpedia redirects plain HTTP, and the Wikidata Query Service lives at `query.wikidata.org`. Two helpers make building queries safer: `sparql_literal/2` escapes backslashes and double quotes in a string literal, and `sparql_iri/2` wraps an atom in `<...>`. Use them whenever a query includes user input, to avoid SPARQL injection.

`make run` queries both endpoints (it needs network access):

```text
DBpedia: Prolog is a programming language that uses first order logic
Wikidata: the French label of Q163468 is Prolog
```

## RDFS Reasoning

Plain RDF states facts. **RDF Schema (RDFS)** adds vocabulary for describing classes and properties, from which a reasoner can derive new facts:
- `rdfs:subClassOf`: every instance of the subclass is an instance of the superclass.
- `rdfs:subPropertyOf`: every use of the subproperty implies the superproperty.
- `rdfs:domain` / `rdfs:range`: the subject (domain) or object (range) of a property belongs to a class.

The **Web Ontology Language (OWL)** goes further, with rules such as inverse and transitive properties. We stay with RDFS here.

The file **rdf_explorer/example.ttl** has a few facts and a small ontology:

```turtle
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix ex: <http://example.org/> .

ex:prolog a ex:Language ;
    rdfs:label "Prolog" ;
    ex:paradigm ex:LogicProgramming .

ex:swi_prolog a ex:Implementation ;
    rdfs:label "SWI-Prolog" ;
    ex:implements ex:prolog .

# A small ontology: class hierarchy plus the domain and range of
# ex:implements.
ex:Implementation rdfs:subClassOf ex:Software .
ex:Language rdfs:subClassOf ex:Notation .
ex:implements rdfs:domain ex:Implementation ;
    rdfs:range ex:Language .

# Scryer Prolog has no rdf:type triple. RDFS can still infer its type
# from the domain of ex:implements.
ex:scryer_prolog rdfs:label "Scryer Prolog" ;
    ex:implements ex:prolog .
```

SWI-Prolog's `library(semweb/rdfs)` provides the basic RDFS queries:

- **`rdfs_individual_of(?Resource, ?Class)`**: `Resource` has an `rdf:type` of `Class` or of a subclass of it.
- **`rdfs_subclass_of(?SubClass, ?SuperClass)`**: `SubClass` is `SuperClass` or a direct or indirect subclass of it.
- **`rdfs_subproperty_of(?SubProperty, ?SuperProperty)`**: the same for properties.

So although no triple says SWI-Prolog is software, RDFS reasoning finds it:

```prolog
?- rdf_register_prefix(ex, 'http://example.org/').
?- rdfs_individual_of(ex:swi_prolog, ex:'Software').
true.
```

`rdfs_individual_of/2` does *not* use domains and ranges, though. Scryer Prolog has no `rdf:type` triple, so `rdfs_individual_of(ex:scryer_prolog, ex:'Implementation')` fails, even though the domain of `ex:implements` says it is an implementation. Also note what RDFS does not say: `ex:prolog ex:paradigm ex:LogicProgramming` does not make Prolog an instance of `LogicProgramming`. A property value is not a type.

The missing domain and range rules take a few lines of Prolog. Here is the file **rdf_explorer/prolog/rdfs_reason.pl**:

```prolog
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
```

Each clause is one RDFS rule. The `rdf_meta` declaration lets callers write `ex:scryer_prolog` instead of the full IRI. `make run` loads the example and asks for Scryer Prolog's types:

```text
Inferred types of scryer_prolog: [http://example.org/Implementation,
  http://example.org/Software,
  http://www.w3.org/2000/01/rdf-schema#Resource]
```

`rdfs:Resource` appears because every resource belongs to it.

## Combining Local and Remote Data

You can combine local RDF data with remote SPARQL queries: keep private triples (customer records, local settings) in your own store and add public facts from DBpedia or Wikidata when you need them. Here is the file **sparql_client/prolog/knowledge_explorer.pl**:

```prolog
%% knowledge_explorer.pl - Combine local RDF facts with DBpedia
:- module(knowledge_explorer, [
    explore_and_enrich/1,
    dbpedia_description/2,
    literal_text/2
]).

:- use_module(library(semweb/rdf_db)).
:- use_module(sparql).

%% explore_and_enrich(+ResourceIRI)
%% Print the local triples about ResourceIRI, then the English
%% description of the DBpedia resource with the same local name.
explore_and_enrich(Resource) :-
    format("=== Local knowledge for ~w ===~n", [Resource]),
    forall(rdf(Resource, P, O),
           format("  ~w -> ~w~n", [P, O])),
    file_base_name(Resource, LocalName),
    format("~n=== DBpedia description of ~w ===~n", [LocalName]),
    (   catch(dbpedia_description(LocalName, Text), Error,
              ( print_message(warning, Error), fail ))
    ->  format("  ~w~n", [Text])
    ;   format("  No description found.~n")
    ).

%% dbpedia_description(+LocalName, -Text)
%% Text is the English dbo:description of the DBpedia resource
%% http://dbpedia.org/resource/LocalName.
dbpedia_description(LocalName, Text) :-
    format(atom(Resource), 'http://dbpedia.org/resource/~w',
           [LocalName]),
    sparql_iri(Resource, IRI),
    format(atom(Query),
           'SELECT ?d WHERE { ~w <http://dbpedia.org/ontology/description> ?d . FILTER (lang(?d) = "en") } LIMIT 1',
           [IRI]),
    sparql_query_dbpedia(Query, row(Literal)),
    literal_text(Literal, Text),
    !.

%% sparql_client returns a literal as literal(Text),
%% literal(lang(Lang, Text)), or literal(type(Type, Text)).
literal_text(literal(lang(_, Text)), Text) :- !.
literal_text(literal(type(_, Text)), Text) :- !.
literal_text(literal(Text), Text).
```

We ask for `dbo:description`, a short phrase, because DBpedia's data changes between releases and its current release has no `dbo:abstract` for the Prolog page. `literal_text/2` handles the three forms in which `sparql_client` returns literals; a pattern such as `row(literal(Text))` alone would miss the language-tagged form DBpedia uses here.

```prolog
?- rdf_assert('http://example.org/Prolog', 'http://example.org/usedFor',
              literal('teaching logic')),
   explore_and_enrich('http://example.org/Prolog').
=== Local knowledge for http://example.org/Prolog ===
  http://example.org/usedFor -> literal(teaching logic)

=== DBpedia description of Prolog ===
  programming language that uses first order logic
```

A small local store plus a few remote queries gives your program access to millions of public triples.

## Optional Practice Problems

1. **Computer Scientists on Wikidata**: Use `wikidata_query/2` to fetch the birth dates of three computer scientists (Wikidata property `wdt:P569`). Look up their IDs on wikidata.org first.
2. **Subproperties**: Add `ex:reimplements rdfs:subPropertyOf ex:implements` to `example.ttl` and a triple that uses it. Extend `instance_of/2` so the domain of `ex:implements` also applies through the subproperty.
3. **Blank Nodes**: Add a resource with a blank node (`[ ... ]` in Turtle) to `example.ttl`. Change `describe_resource/1` to print the blank node's own triples, indented, instead of its internal name.
