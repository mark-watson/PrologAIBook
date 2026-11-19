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
