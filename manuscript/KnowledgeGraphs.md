# Knowledge Graphs and Knowledge Representation

Knowledge representation is at the heart of symbolic AI, and Prolog's database of facts and rules is itself a knowledge representation system. A knowledge graph stores information as triples (subject, predicate, object), which is exactly the shape of a Prolog fact. In this chapter we build two tools: **kg_creator** builds knowledge graphs, exports them to standard formats, and enriches them from DBpedia, and **kg_query** finds paths and does multi-hop reasoning over a larger graph.

{width: "80%"}
![Architecture diagram for the Knowledge Graph Creator example](FIG_kg_creator.jpg)

## Representing Knowledge in Prolog

A knowledge graph is a set of triples, each linking a subject to an object through a named predicate. In Prolog this is direct:

```prolog
triple(john, works_at, acme).
triple(acme, located_in, london).
```

No translation layer is needed: Prolog's fact base *is* a knowledge graph. `triple/3` is the storage schema, and unification is the query engine.

We keep the triple store inside a module, so other code uses only the exported predicates. `:- dynamic triple/3.` lets us add triples at run time, since a knowledge graph grows as we learn things.

## Building a Knowledge Graph

The **kg_creator** project is a small knowledge graph builder. It stores triples as dynamic facts, queries them by pattern matching, and exports the graph in two formats: N-Triples RDF (for Semantic Web tools) and Neo4j Cypher `CREATE` statements (for graph databases).

Here is the file **kg_creator/prolog/kg_builder.pl**:

```prolog
:- module(kg_builder, [
    add_triple/3,
    query_triples/3,
    clear_all_triples/0,
    export_rdf/1,
    export_rdf/2,
    export_cypher/1
]).

:- dynamic triple/3.  % triple(Subject, Predicate, Object)

%% add_triple(+S, +P, +O)
%% Add a triple if not already present (always succeeds)
add_triple(S, P, O) :-
    (   triple(S, P, O)
    ->  true
    ;   assertz(triple(S, P, O))
    ).

%% query_triples(?S, ?P, ?O)
query_triples(S, P, O) :- triple(S, P, O).

%% clear_all_triples - remove every triple from the store
clear_all_triples :-
    retractall(triple(_, _, _)).

%% export_rdf(+FileName)
%% export_rdf(+FileName, +BaseIRI)
%% Export triples as N-Triples RDF. N-Triples needs absolute IRIs, so
%% each name becomes BaseIRI followed by the name (the default base is
%% http://example.org/kg/). An object that is an atom with no spaces
%% names a resource and becomes an IRI; any other object (a string, a
%% number, or an atom with spaces) becomes a literal, with \, " and
%% newlines escaped. A subject or predicate that is not a valid name
%% makes export_rdf fail with a message.
export_rdf(FileName) :-
    export_rdf(FileName, 'http://example.org/kg/').

export_rdf(FileName, Base) :-
    setup_call_cleanup(
        open(FileName, write, Stream),
        forall(triple(S, P, O),
               write_ntriple(Stream, Base, S, P, O)),
        close(Stream)
    ).

write_ntriple(Stream, Base, S, P, O) :-
    (   valid_name(S), valid_name(P)
    ->  rdf_object(Base, O, OText),
        format(Stream, '<~w~w> <~w~w> ~w .~n', [Base, S, Base, P, OText])
    ;   format(user_error, 'export_rdf: invalid name in triple ~w~n',
               [triple(S, P, O)]),
        fail
    ).

valid_name(A) :-
    atom(A),
    A \== '',
    \+ sub_atom(A, _, _, _, ' ').

rdf_object(Base, O, Text) :-
    valid_name(O),
    !,
    format(atom(Text), '<~w~w>', [Base, O]).
rdf_object(_, O, Text) :-
    escape_literal(O, Esc),
    format(atom(Text), '"~w"', [Esc]).

%% escape_literal(+In, -Out) - escape \ " and newline for N-Triples
escape_literal(In, Out) :-
    format(atom(A), '~w', [In]),
    atom_chars(A, Chars),
    esc_chars(Chars, EscChars),
    atom_chars(Out, EscChars).

esc_chars([], []).
esc_chars(['\\'|Cs], ['\\','\\'|Esc]) :- !, esc_chars(Cs, Esc).
esc_chars(['"'|Cs], ['\\','"'|Esc]) :- !, esc_chars(Cs, Esc).
esc_chars(['\n'|Cs], ['\\','n'|Esc]) :- !, esc_chars(Cs, Esc).
esc_chars([C|Cs], [C|Esc]) :- esc_chars(Cs, Esc).

%% export_cypher(+FileName)
%% Export triples as Neo4j Cypher CREATE statements.  Node names and
%% relationship types are backtick-quoted; embedded backticks are
%% escaped by doubling.
export_cypher(FileName) :-
    setup_call_cleanup(
        open(FileName, write, Stream),
        (   forall(
                triple(S, P, O),
                (   backtick_quote(S, QS),
                    backtick_quote(P, QP),
                    backtick_quote(O, QO),
                    format(Stream, 'CREATE (~w)-[:~w]->(~w)~n',
                        [QS, QP, QO])
                )
            )
        ),
        close(Stream)
    ).

backtick_quote(A, Quoted) :-
    format(atom(A1), '~w', [A]),
    atom_chars(A1, Chars),
    bt_chars(Chars, EscChars),
    atom_chars(Esc, EscChars),
    atom_concat('`', Esc, T),
    atom_concat(T, '`', Quoted).

bt_chars([], []).
bt_chars(['`'|Cs], ['`','`'|Esc]) :- !, bt_chars(Cs, Esc).
bt_chars([C|Cs], [C|Esc]) :- bt_chars(Cs, Esc).
```

### Adding Triples with Deduplication

`add_triple/3` first checks whether the triple exists and adds it only if it does not. So it never creates duplicates, and it always succeeds:

```prolog
?- add_triple(john, works_at, acme).
?- add_triple(john, works_at, acme).   % no duplicate created
?- findall(T, query_triples(john, works_at, _), Results),
   length(Results, 1).                  % still just one
```

The if-then-else `( Condition -> Then ; Else )` does the work. If `triple(S, P, O)` succeeds, `-> true` succeeds and changes nothing. If it fails, the triple is new, and the `; assertz(triple(S, P, O))` branch adds it.

### Querying with Pattern Matching

`query_triples/3` just calls `triple/3`, so any mix of bound and unbound arguments works:

```prolog
?- query_triples(john, works_at, X).    % what does john work at?
X = acme.

?- query_triples(X, located_in, london). % what is located in london?
X = acme.

?- query_triples(X, _, Y).              % all triples
```

Backtracking returns every matching triple, with no loop to write.

### Exporting to RDF and Cypher

The export predicates use a common Prolog pattern: `setup_call_cleanup/3` closes the output file even if writing fails, and `forall/2` writes one line per triple.

N-Triples requires absolute IRIs, so `export_rdf/2` puts a base IRI in front of every name; `export_rdf/1` uses `http://example.org/kg/`. An object that is an atom with no spaces names a resource and becomes an IRI. Any other object (a string, a number, or an atom with spaces) becomes a literal, with `\`, `"`, and newlines escaped. The tests load the exported file with SWI-Prolog's own N-Triples parser to check that it is valid.

```prolog
?- add_triple(john, works_at, acme),
   add_triple(acme, located_in, london),
   add_triple(john, age, 42),
   export_rdf('output.nt'),
   export_cypher('output.cypher').
```

The resulting **output.nt** contains N-Triples RDF:

```text
<http://example.org/kg/john> <http://example.org/kg/works_at> <http://example.org/kg/acme> .
<http://example.org/kg/acme> <http://example.org/kg/located_in> <http://example.org/kg/london> .
<http://example.org/kg/john> <http://example.org/kg/age> "42" .
```

And **output.cypher** contains Neo4j Cypher statements:

```text
CREATE (`john`)-[:`works_at`]->(`acme`)
CREATE (`acme`)-[:`located_in`]->(`london`)
CREATE (`john`)-[:`age`]->(`42`)
```

The Cypher export is deliberately simple. Each `CREATE` makes new nodes, so loading these lines creates two `acme` nodes; Neo4j's `MERGE` would reuse existing ones. And `42` should be a property of `john`, not a node. The list later in this chapter covers these and other changes a production exporter needs.

### Running the kg_creator Examples

```shell
cd source-code/kg_creator
swipl -s load.pl
```

```prolog
?- add_triple(john, works_at, acme).
?- add_triple(acme, located_in, london).
?- query_triples(john, _, X).
X = acme.
?- export_rdf('output.nt').
?- export_cypher('output.cypher').
```

`make run` prints both exports to the terminal, and `make test` runs the tests.

## Multi-Hop Reasoning Over Knowledge Graphs

The **kg_query** project *reasons* over a knowledge graph: it finds paths, checks connectivity, and lists what is reachable from an entity. Recursive path finding with backtracking takes a few lines in Prolog.

It uses typed entities and named relations. Here is the module header of **kg_query/prolog/kg_reason.pl**:

```prolog
:- module(kg_reason, [
    entity/2,          % raw facts from sample_data
    relation/3,
    entity_of_type/2,
    relates/3,
    path/3,
    path/4,
    connected/2,
    neighbors/3,
    path_length/3,
    shortest_path/3,
    all_paths/3,
    reachable/2,
    relation_count/2
]).

:- use_module(sample_data).   % static facts: entity/2, relation/3
```

The data comes from **sample_data.pl** as static facts, so loading it twice never duplicates anything. `entity_of_type/2` and `relates/3` are named wrappers for the raw `entity/2` and `relation/3` facts. `path/4` adds a depth limit, so it always terminates.

### Path Finding with Cycle Detection

`path/3` finds a chain of relations from one entity to another. It keeps a list of visited nodes to avoid cycles:

```prolog
path(Start, End, Path) :-
    path(Start, End, [Start], Path).

path(Start, End, Visited, [Start, End]) :-
    relation(Start, _, End),
    \+ member(End, Visited).
path(Start, End, Visited, [Start|Rest]) :-
    relation(Start, _, Mid),
    Mid \= End,
    \+ member(Mid, Visited),
    path(Mid, End, [Mid|Visited], Rest).
```

`path/3` calls a helper that carries the visited list. The `\+ member(..., Visited)` tests stop the path from returning to a node, which matters in a dense graph with many cycles. Each step follows one relation to a node `Mid` and adds `Mid` to the visited list before recursing. On backtracking, `path/3` returns every cycle-free path, longest and shortest alike.

### Connectivity and Reachability

`connected/2` checks whether a path exists from either entity to the other:

```prolog
connected(A, B) :- path(A, B, _).
connected(A, B) :- path(B, A, _).
```

`reachable/2` lists the entities linked to a starting point: those it can reach by following edges forward, plus those that can reach it. Each direction is a breadth-first search:

```prolog
reachable(Entity, Reachable) :-
    reachable_fwd([Entity], [Entity], Fwd),
    reachable_bwd([Entity], [Entity], Bwd),
    append(Fwd, Bwd, All),
    sort(All, Reachable).
```

Each search keeps a queue of nodes to visit and a list of nodes already seen. New neighbors go to the back of the queue, so the search finishes each level before starting the next.

### Neighbors and Shortest Paths

`neighbors/3` lists an entity's direct links:

```prolog
neighbors(Entity, Neighbors, Predicates) :-
    findall(Neighbor-Predicate, relation(Entity, Predicate, Neighbor),
        Pairs),
    pairs_keys_values(Pairs, Neighbors, Predicates).
```

The first path that `path/3` finds is not always the shortest, because depth-first search follows the first relation it meets as far as it can. From `mark` to `swi`, `path/3` first returns `[mark, ai, prolog, swi]`, though `mark` uses `prolog` directly. For the shortest path we need breadth-first search:

```prolog
%% shortest_path(+Start, +End, -Path) - A path with the fewest edges,
%% found by breadth-first search. Fails if End cannot be reached.
shortest_path(Start, End, Path) :-
    bfs([[Start]], [Start], End, RevPath),
    reverse(RevPath, Path).

bfs([[End|Rest]|_], _, End, [End|Rest]) :- !.
bfs([[Node|Rest]|Queue], Seen, End, Path) :-
    findall([Next, Node|Rest],
            ( relation(Node, _, Next), \+ memberchk(Next, Seen) ),
            Children0),
    sort(Children0, Children),
    findall(N, member([N|_], Children), NewNodes),
    append(Seen, NewNodes, Seen1),
    append(Queue, Children, Queue1),
    bfs(Queue1, Seen1, End, Path).

%% path_length(+Start, +End, -Length) - Number of edges on a shortest
%% path between two entities.
path_length(Start, End, Length) :-
    shortest_path(Start, End, Path),
    length(Path, N),
    Length is N - 1.
```

Each queue entry is a path stored in reverse, newest node first. Because BFS finishes each level before the next, the first path to reach `End` has the fewest edges. The `Seen` list stops the search from adding a node twice.

```prolog
?- shortest_path(mark, swi, P), path_length(mark, swi, L).
P = [mark, prolog, swi],
L = 2.
```

`all_paths/3` collects every cycle-free path with `findall/3`.

{width: "80%"}
![Architecture diagram for the Knowledge Graph Query example](FIG_kg_query.jpg)

### The Sample Knowledge Graph

The **kg_query** project includes a rich sample dataset in **kg_query/prolog/sample_data.pl** with 374 assertions (132 entities and 242 relations) spanning eight entity types:

| Type | Count | Examples |
|------|-------|---------|
| People | 28 | mark, sarah, chen |
| Languages | 18 | prolog, lisp, python |
| Fields | 16 | ai, nlp, robotics |
| Implementations | 18 | swi, cpython, jvm |
| Organizations | 14 | google, meta, openai |
| Concepts | 16 | transformer, unification |
| Projects | 14 | gpt4, bert, coq |
| Publications | 8 | attention_paper, gpt_paper |

The relations connect these entities in meaningful ways: people research fields, use languages, work at organizations, collaborate with each other, and author publications. Languages are implemented by tools, fields use concepts, organizations develop projects, and languages form dialect chains (e.g., clojure → lisp).

This dense graph supports multi-hop queries. For example, can we trace a path from a person to a concept with no direct link between them?

```prolog
?- path(mark, transformer, Path).
Path = [mark, nlp, transformer] .
```

Mark works on NLP, which uses the transformer concept. No single fact says this; it follows from two facts.

### Running the kg_query Examples

```shell
cd source-code/kg_query
swipl -s load.pl
```

```prolog
?- relation(mark, uses, prolog).       % direct relation
?- path(mark, swi, Path).               % first path found
Path = [mark, ai, prolog, swi] .

?- shortest_path(mark, swi, Path).      % fewest edges
Path = [mark, prolog, swi].

?- connected(mark, swi).                % connectivity check
?- reachable(mark, Reachable).          % all reachable entities
?- all_paths(sarah, bert, Paths).        % all paths between two entities
?- path(clojure, lisp, Path).           % dialect chain
Path = [clojure, lisp] .

?- path(mark, transformer, Path).       % cross-domain path
?- relation_count(uses, Count).         % count all "uses" relations
```

Running tests:

```shell
make test
```

The tests check direct relations, multi-hop paths, cycle-free paths, reachability, and shortest paths:

```prolog
test(multi_hop_path, [nondet]) :-
    path(mark, swi, Path),
    length(Path, N),
    N >= 2.

test(path_no_cycles, [nondet]) :-
    path(mark, swi, Path),
    sort(Path, Uniq),
    length(Path, N),
    length(Uniq, N).    % length matches = no duplicates

test(dialect_chain_clojure_lisp, [nondet]) :-
    path(clojure, lisp, Path),
    length(Path, N),
    N >= 2.

test(shortest_not_longer_than_any_path) :-
    path_length(sarah, bert, L),
    forall(path(sarah, bert, P), (length(P, N), N - 1 >= L)).
```

The last test compares `path_length/3` with every path `path/3` can find.

## Generating RDF and Neo4j Cypher Data from Prolog

The export predicates in **kg_creator** connect the Prolog graph to other graph tools. N-Triples is the simplest RDF format: one triple per line, `<subject> <predicate> object .`, where the object is an IRI in angle brackets or a quoted literal. Any RDF tool can load it, including Apache Jena, RDF4J, and SWI-Prolog's semweb library (see the Semantic Web chapter).

Cypher is Neo4j's query language. You can paste the generated statements into the Neo4j browser to build the graph there.

A production exporter would also need:
- **Real vocabularies** for RDF: map predicates such as `works_at` to terms from shared vocabularies such as schema.org, instead of a private base IRI
- **Datatypes and language tags** for literals (`"42"^^xsd:integer`, `"Paris"@fr`)
- **`MERGE` instead of `CREATE`** in Cypher, so a node named twice becomes one node
- **Node labels and properties** for Cypher (e.g., `CREATE (john:Person {name: "John"})`)
- **Batch import** using Cypher's `UNWIND` for large graphs

The essential idea stays the same: a Prolog triple store is a working knowledge graph, and a few lines of formatting code turn it into a standard format.

## Integrating with DBpedia

A local knowledge graph becomes more useful when linked to the web of Linked Open Data. DBpedia (Wikipedia's content as RDF) and Wikidata (Wikimedia's structured database) are huge public triple stores, and both offer public SPARQL endpoints.

SWI-Prolog's `library(semweb/sparql_client)` queries these endpoints, so we can copy remote facts into our local graph. This is called **graph enrichment**. The Semantic Web chapter covers SPARQL in more depth.

Here is the file **kg_creator/prolog/kg_enrich.pl**, which asks DBpedia who designed a programming language:

```prolog
%% kg_enrich.pl - Enrich the local knowledge graph from DBpedia
:- module(kg_enrich, [
    enrich_designers/2,
    query_designer/2,
    literal_text/2
]).

:- use_module(library(semweb/sparql_client)).
:- use_module(kg_builder).

%% DBpedia page names for some of our local entity names. A local
%% name rarely matches the remote one exactly, so we keep a map.
dbpedia_page(prolog, 'Prolog').
dbpedia_page(python, 'Python_(programming_language)').
dbpedia_page(lisp,   'Lisp_(programming_language)').
dbpedia_page(haskell, 'Haskell').

%% enrich_designers(+Lang, -Designers)
%% Ask DBpedia who designed Lang, add a designed_by triple for each
%% answer, and return the names. Fails if the query fails or finds
%% nothing. DBpedia has two kinds of properties: dbo: terms from its
%% curated ontology and dbp: terms copied from Wikipedia infoboxes.
%% Some pages have only one of them, so we ask for either.
enrich_designers(Lang, Designers) :-
    dbpedia_page(Lang, Page),
    format(string(Query),
           "SELECT DISTINCT ?name WHERE { \c
              { <http://dbpedia.org/resource/~w> \c
                    <http://dbpedia.org/ontology/designer> ?d } \c
              UNION \c
              { <http://dbpedia.org/resource/~w> \c
                    <http://dbpedia.org/property/designers> ?d } \c
              ?d <http://www.w3.org/2000/01/rdf-schema#label> ?name . \c
              FILTER (lang(?name) = 'en') }",
           [Page, Page]),
    findall(Name,
            ( sparql_query(Query, row(Lit),
                           [ endpoint('https://dbpedia.org/sparql'),
                             timeout(20) ]),
              literal_text(Lit, Name) ),
            Designers),
    Designers \== [],
    forall(member(D, Designers), add_triple(Lang, designed_by, D)).

%% literal_text(+Literal, -Text)
%% sparql_client returns a literal as literal(Text),
%% literal(lang(Lang, Text)), or literal(type(Type, Text)).
literal_text(literal(lang(_, Text)), Text) :- !.
literal_text(literal(type(_, Text)), Text) :- !.
literal_text(literal(Text), Text).

%% query_designer(+Lang, -Designer)
%% Use the local graph if it knows the answer. Otherwise fetch it from
%% DBpedia once, store it, and answer from the local graph.
query_designer(Lang, Designer) :-
    query_triples(Lang, designed_by, _),
    !,
    query_triples(Lang, designed_by, Designer).
query_designer(Lang, Designer) :-
    catch(enrich_designers(Lang, _), Error,
          ( print_message(warning, Error), fail )),
    query_triples(Lang, designed_by, Designer).
```

Three details matter in practice:

- **Two vocabularies.** DBpedia has curated `dbo:` properties from its ontology and raw `dbp:` properties copied from Wikipedia infoboxes. Some pages have only one kind: Prolog's page has no `dbo:designer` but does have `dbp:designers`. The `UNION` asks for either.
- **Name mapping.** Our local name `python` is the DBpedia page `Python_(programming_language)`. `dbpedia_page/2` maps one to the other. Real systems keep such maps, or search for the remote entity by label.
- **Literal forms.** `sparql_query/3` returns a literal as `literal(Text)`, `literal(lang(Lang, Text))`, or `literal(type(Type, Text))`, depending on how the endpoint encodes it. DBpedia returns these labels as `literal(type(rdf:langString, Text))`, so code that matches only `literal(Text)` silently finds nothing. `literal_text/2` accepts all three.
- **Caching.** `query_designer/2` answers from the local graph when it can. Only when the local graph knows nothing does it query DBpedia, and the answer is stored, so the next call needs no network. A network error prints a warning and the query fails.

The `enrich` target in the Makefile runs this against the live endpoint (it needs network access):

```text
$ make enrich
python designed by: [Guido van Rossum]
lisp designed by: [John McCarthy (computer scientist)]
prolog designed by: [Alain Colmerauer]
```

Public data is incomplete, and it can be wrong. DBpedia names only Alain Colmerauer for Prolog, though he designed it with Philippe Roussel. And for Haskell it lists *Lazy ML*, a programming language, as a designer. Treat enriched facts as claims from a source, not as truth. One way is to store the source with each fact, for example `triple(python, designed_by, 'Guido van Rossum')` plus `source(python, designed_by, dbpedia)`.

## Optional Practice Problems

1. **Text-to-Fact Parser**: In `kg_creator`, write `load_triples(+File)`, which reads lines such as `john works_at acme` and adds each as a triple. (Hint: `read_line_to_string/2` and `split_string/4`.)
2. **Explain a Path**: In `kg_query`, write `explain_path(+Path)`, which prints each step of a path with its relation, such as `mark uses prolog` and `prolog implemented_by swi`.
3. **Track Sources**: Change `kg_enrich.pl` to record where each enriched fact came from, and change `query_designer/2` to return `Designer-Source` pairs.
