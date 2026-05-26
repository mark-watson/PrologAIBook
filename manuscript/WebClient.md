# Web Clients in Prolog

SWI-Prolog includes comprehensive HTTP client libraries that make it straightforward to interact with REST APIs, parse JSON, and scrape web content — all from within Prolog.

{width: "80%"}
![Architecture diagram for the HTTP Client example](FIG_http_client.jpg)

## HTTP GET and POST Requests

SWI-Prolog ships with `library(http/http_client)`, a full HTTP/1.1 client that handles GET, POST, PUT, and DELETE requests. The companion library `library(http/http_json)` adds automatic JSON serialisation and deserialisation, so a single `http_get/3` call can fetch a URL and return its JSON body as a Prolog dict.

The key predicates are:
- **`http_get(+URL, -Reply, +Options)`** — Sends a GET request. The `json_object(dict)` option tells the library to parse the response body as a SWI-Prolog dict rather than the older `json/1` term format.
- **`http_post(+URL, +Data, -Reply, +Options)`** — Sends a POST request. The `Data` argument can be `atom(Body)`, `json(Term)`, or other content types. Custom request headers (such as `Content-Type` or `Authorization`) are passed via the options list.

Error handling is straightforward: if the server returns a non-2xx status code, `http_get` and `http_post` throw an `http_error` exception, which you can catch with `catch/3`.

The **http_client** project wraps SWI-Prolog's HTTP libraries. Here is the file **http_client/prolog/rest_client.pl**:

```prolog
%% rest_client.pl - HTTP REST client utilities
:- module(rest_client, [
    http_get_json/2,
    http_post_json/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).

%% http_get_json(+URL, -JsonTerm)
http_get_json(URL, JsonTerm) :-
    http_get(URL, JsonTerm, [json_object(dict)]).

%% http_post_json(+URL, +JsonPayload, -Response)
http_post_json(URL, Payload, Response) :-
    atom_json_dict(PayloadAtom, Payload, []),
    http_post(URL, atom(PayloadAtom), Response,
              [request_header('Content-Type'='application/json'),
               json_object(dict)]).
```

The `http_get_json/2` predicate is a thin wrapper that adds the `json_object(dict)` option. The `http_post_json/3` predicate serialises a Prolog dict into a JSON string using `atom_json_dict/3`, then posts it with the appropriate `Content-Type` header. The response is automatically parsed back into a dict.

You can test this in the REPL:

```prolog
?- http_get_json('https://jsonplaceholder.typicode.com/todos/1', R).
R = _{ completed:false, id:1, title:"delectus aut autem", userId:1 }.
```

## Working with JSON

Most modern web APIs return JSON. SWI-Prolog provides two representations for JSON data:
1. **Dicts** (the modern approach) — SWI-Prolog dicts are key-value stores accessed with dot notation (e.g., `Dict.name`). They map naturally to JSON objects and are the recommended format.
2. **`json/1` terms** (the legacy approach) — The older `json([key=value, ...])` compound term format. Still supported but less ergonomic.

The `atom_json_dict/3` predicate is the core conversion tool. It converts between a JSON-formatted atom (or string) and a Prolog dict in both directions:

```prolog
%% Parsing: JSON string -> Prolog dict
?- atom_json_dict('{"name":"Alice","age":30}', Dict, []).
Dict = _{ age:30, name:"Alice" }.

%% Generating: Prolog dict -> JSON string
?- atom_json_dict(Json, _{name:"Bob", score:95}, []).
Json = '{"name":"Bob","score":95}'.
```

To traverse nested JSON structures, use chained dot notation: `Dict.address.city` accesses the `city` field inside a nested `address` object. For lists, use standard Prolog list operations — a JSON array becomes a Prolog list.

The **http_client** project also includes JSON utilities. Here is the file **http_client/prolog/json_utils.pl**:

```prolog
%% json_utils.pl - JSON parsing and generation utilities
:- module(json_utils, [
    parse_json_string/2,
    json_to_prolog/2
]).

:- use_module(library(json)).

%% parse_json_string(+JsonString, -PrologTerm)
parse_json_string(JsonString, Term) :-
    atom_json_dict(JsonString, Term, []).

%% json_to_prolog(+JsonDict, -PrologFacts)
%% Convert a JSON dict to a list of key-value pairs
json_to_prolog(Dict, Pairs) :-
    is_dict(Dict),
    dict_pairs(Dict, _, Pairs).
```

The `json_to_prolog/2` predicate uses `dict_pairs/3` to decompose a dict into a list of `Key-Value` pairs. This is useful when you need to iterate over all fields in a JSON object without knowing the keys in advance.

## Web Scraping

SWI-Prolog can also fetch and parse HTML pages directly. The workflow combines three libraries:
1. **`library(http/http_client)`** — Fetches the raw HTML content from a URL.
2. **`library(sgml)`** — Parses the HTML string into a DOM tree (a nested Prolog term representing the document structure).
3. **`library(xpath)`** — Queries the DOM tree using XPath expressions to extract specific elements.

The `load_html/3` predicate from `library(sgml)` is tolerant of malformed HTML, making it suitable for scraping real-world web pages. Once you have a DOM tree, `xpath/3` lets you select elements declaratively — for example, `xpath(DOM, //a(@href), Href)` extracts the `href` attribute from every `<a>` tag in the document.

The **web_scraper** project implements a simple HTML scraper. Here is the file **web_scraper/prolog/scraper.pl**:

```prolog
%% scraper.pl - Web scraping using HTTP client and SGML/HTML parser
:- module(scraper, [
    fetch_page/2,
    extract_links/2,
    extract_text/2
]).

:- use_module(library(http/http_client)).
:- use_module(library(sgml)).
:- use_module(library(xpath)).

%% fetch_page(+URL, -DOM) - Fetch and parse an HTML page
fetch_page(URL, DOM) :-
    http_get(URL, Content, []),
    setup_call_cleanup(
        new_memory_file(MemFile),
        (   setup_call_cleanup(
                open_memory_file(MemFile, write, Out),
                write(Out, Content),
                close(Out)
            ),
            setup_call_cleanup(
                open_memory_file(MemFile, read, In),
                load_html(In, DOM, []),
                close(In)
            )
        ),
        free_memory_file(MemFile)
    ).

%% extract_links(+DOM, -Links) - Extract all href links from HTML
extract_links(DOM, Links) :-
    findall(Href, xpath(DOM, //a(@href), Href), Links).

%% extract_text(+DOM, -Text) - Extract all text content
extract_text(DOM, Text) :-
    findall(T, xpath(DOM, //text, T), Texts),
    atomic_list_concat(Texts, ' ', Text).
```

The `fetch_page/2` predicate uses SWI-Prolog's memory file API to bridge between the HTTP response (a Prolog atom) and the stream-based `load_html/3` parser. The nested `setup_call_cleanup/3` calls ensure that all streams and the memory file are properly cleaned up, even if an error occurs. This is idiomatic SWI-Prolog resource management.

The `extract_links/2` and `extract_text/2` predicates both use `findall/3` with `xpath/3` to collect results. XPath expressions like `//a(@href)` select all `<a>` elements and extract their `href` attribute, while `//text` selects all text nodes in the document.

{width: "80%"}
![Architecture diagram for the Web Scraper example](FIG_web_scraper.jpg)

## Practical Applications

These HTTP client and scraping building blocks are used throughout the book:

- **LLM API Integration** — The `rest_client` module is the foundation for calling the Google Gemini and Ollama APIs (see the LLM Integration chapter). A single `http_post_json/3` call sends a prompt and receives the model's response.
- **SPARQL Queries** — The Semantic Web chapter uses HTTP GET requests to query remote SPARQL endpoints like DBpedia and Wikidata, parsing the JSON results into Prolog terms for local reasoning.
- **Knowledge Graph Enrichment** — Web scraping can extract structured data from HTML pages and assert it into a local knowledge graph. For example, scraping a product catalogue and converting the extracted attributes into `entity/3` facts.
- **Data Pipeline Preprocessing** — Fetching CSV or JSON datasets from public APIs (such as government open data portals) and transforming them into Prolog facts for analysis with the anomaly detection or probabilistic reasoning modules.
