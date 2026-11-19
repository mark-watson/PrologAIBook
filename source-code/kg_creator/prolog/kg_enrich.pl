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
