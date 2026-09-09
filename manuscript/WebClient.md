# Web Clients in Prolog

SWI-Prolog includes comprehensive HTTP client libraries that make it straightforward to interact with REST APIs, parse JSON, and scrape web content, all from within Prolog.

{width: "80%"}
![Architecture diagram for the HTTP Client example](FIG_http_client.jpg)

## HTTP GET and POST Requests

SWI-Prolog ships with `library(http/http_client)`, a full HTTP/1.1 client that handles GET, POST, PUT, and DELETE requests. The companion library `library(http/http_json)` adds automatic JSON serialisation and deserialisation, so a single `http_get/3` call can fetch a URL and return its JSON body as a Prolog dict.

The key predicates are:
- **`http_get(+URL, -Reply, +Options)`** - Sends a GET request. The `json_object(dict)` option tells the library to parse the response body as a SWI-Prolog dict rather than the older `json/1` term format.
- **`http_post(+URL, +Data, -Reply, +Options)`** - Sends a POST request. The `Data` argument can be `atom(Body)`, `json(Term)`, or other content types. Custom request headers (such as `Content-Type` or `Authorization`) are passed via the options list.

Error handling is straightforward: if the server returns a non-2xx status code, `http_get` and `http_post` throw an `http_error` exception, which you can catch with `catch/3`.

The **http_client** project wraps SWI-Prolog's HTTP libraries. Here is the file **http_client/prolog/rest_client.pl**:

```prolog
%% rest_client.pl - HTTP REST client utilities
:- module(rest_client, [
    http_get_json/2,
    http_get_json/3,
    http_post_json/3,
    http_post_json/4
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).

%% http_get_json(+URL, -JsonTerm)
http_get_json(URL, JsonTerm) :-
    http_get_json(URL, JsonTerm, []).

%% http_get_json(+URL, -JsonTerm, +Options)
%% Extra Options are passed through to http_get/3.
http_get_json(URL, JsonTerm, Options) :-
    append(Options, [status_code(Code), json_object(dict)],
           RequestOptions),
    wrapped_call(
        http_get(URL, JsonTerm, RequestOptions),
        Code).

%% http_post_json(+URL, +JsonPayload, -Response)
http_post_json(URL, Payload, Response) :-
    http_post_json(URL, Payload, Response, []).

%% http_post_json(+URL, +JsonPayload, -Response, +Options)
%% Extra Options are passed through to http_post/4.
http_post_json(URL, Payload, Response, Options) :-
    append(Options,
           [request_header('Content-Type'='application/json'),
            status_code(Code),
            json_object(dict)],
           RequestOptions),
    wrapped_call(
        http_post(URL, json(Payload), Response, RequestOptions),
        Code).

%% wrapped_call(:Goal, +Code)
%% Fail (with a warning) on transport errors or non-2xx replies.
wrapped_call(Goal, Code) :-
    (   catch(Goal, E, (log_http_error(E), fail))
    ->  (   success_code(Code)
        ->  true
        ;   log_http_error(bad_status(Code)),
            fail
        )
    ;   log_http_error(request_failed),
        fail
    ).

success_code(Code) :- Code >= 200, Code < 300.

log_http_error(Error) :-
    print_message(warning, http_client_error(Error)).
```

The `http_get_json/2` predicate is a thin wrapper that adds the `json_object(dict)` option. The `http_post_json/3` predicate posts the payload as `json(Payload)` with the appropriate `Content-Type` header, and the library serialises it directly. The response is automatically parsed back into a dict. Both get and post fail with a warning on transport errors or a non-2xx status. The Options variants pass extra options to the underlying `http_get/3` and `http_post/4`.

You can test this in the REPL:

```prolog
?- http_get_json('https://jsonplaceholder.typicode.com/todos/1', R).
R = _{ completed:false, id:1, title:"delectus aut autem", userId:1 }.
```

## Working with JSON

Most modern web APIs return JSON. SWI-Prolog provides two representations for JSON data:
1. **Dicts** (the modern approach) - SWI-Prolog dicts are key-value stores accessed with dot notation (e.g., `Dict.name`). They map naturally to JSON objects and are the recommended format.
2. **`json/1` terms** (the legacy approach) - The older `json([key=value, ...])` compound term format. Still supported but less ergonomic.

The `atom_json_dict/3` predicate is the core conversion tool. It converts between a JSON-formatted atom (or string) and a Prolog dict in both directions:

```prolog
%% Parsing: JSON string -> Prolog dict
?- atom_json_dict('{"name":"Alice","age":30}', Dict, []).
Dict = _{ age:30, name:"Alice" }.

%% Generating: Prolog dict -> JSON string
?- atom_json_dict(Json, _{name:"Bob", score:95}, []).
Json = '{"name":"Bob","score":95}'.
```

To traverse nested JSON structures, use chained dot notation: `Dict.address.city` accesses the `city` field inside a nested `address` object. For lists, use standard Prolog list operations: a JSON array becomes a Prolog list.

The **http_client** project also includes JSON utilities. Here is the file **http_client/prolog/json_utils.pl**:

```prolog
%% json_utils.pl - JSON parsing and generation utilities
:- module(json_utils, [
    parse_json_string/2,
    json_dict_pairs/2,
    json_to_prolog/2
]).

:- use_module(library(json)).

%% parse_json_string(+JsonString, -PrologTerm)
parse_json_string(JsonString, Term) :-
    atom_json_dict(JsonString, Term, []).

%% json_dict_pairs(+JsonDict, -Pairs)
%% Convert a JSON dict to a list of Key-Value pairs.
json_dict_pairs(Dict, Pairs) :-
    is_dict(Dict),
    dict_pairs(Dict, _, Pairs).

%% json_to_prolog(+JsonDict, -Pairs)
%% Deprecated alias for json_dict_pairs/2, kept for compatibility.
json_to_prolog(Dict, Pairs) :-
    print_message(warning, deprecated(json_to_prolog/2,
                                      json_dict_pairs/2)),
    json_dict_pairs(Dict, Pairs).
```

The `json_dict_pairs/2` predicate uses `dict_pairs/3` to decompose a dict into a list of `Key-Value` pairs. This is useful when you need to iterate over all fields in a JSON object without knowing the keys in advance. The older name `json_to_prolog/2` is kept as a deprecated alias that prints a warning and forwards to `json_dict_pairs/2`.

## Web Scraping

SWI-Prolog can also fetch and parse HTML pages directly. The workflow combines three libraries:
1. **`library(http/http_client)`** - Fetches the raw HTML content from a URL.
2. **`library(sgml)`** - Parses the HTML string into a DOM tree (a nested Prolog term representing the document structure).
3. **`library(xpath)`** - Queries the DOM tree using XPath expressions to extract specific elements.

The `load_html/3` predicate from `library(sgml)` is tolerant of malformed HTML, making it suitable for scraping real-world web pages. Once you have a DOM tree, `xpath/3` lets you select elements declaratively, for example, `xpath(DOM, //a(@href), Href)` extracts the `href` attribute from every `<a>` tag in the document.

The **web_scraper** project implements a simple HTML scraper. Here is the file **web_scraper/prolog/scraper.pl**:

```prolog
%% scraper.pl - Web scraping using HTTP client and SGML/HTML parser
:- module(scraper, [
    fetch_page/2,
    extract_links/2,
    extract_text/2,
    parse_html_dom/2,
    strip_script_style/2
]).

:- use_module(library(http/http_client)).
:- use_module(library(sgml)).
:- use_module(library(xpath)).

%% fetch_page(+URL, -DOM) - Fetch and parse an HTML page
%% Fails (with a warning) on transport errors or non-200 replies.
fetch_page(URL, DOM) :-
    catch(
        http_get(URL, Content,
                 [to(string),
                  timeout(20),
                  status_code(Code),
                  user_agent('PrologAIBook-Scraper/1.0')]),
        E,
        (   print_message(warning,
                          scraper_error(transport(URL, E))),
            fail
        )),
    (   Code == 200
    ->  true
    ;   print_message(warning, scraper_error(status(URL, Code))),
        fail
    ),
    parse_html_dom(Content, DOM).

%% parse_html_dom(+HtmlString, -DOM) - Parse an HTML string into a DOM
parse_html_dom(Content, DOM) :-
    setup_call_cleanup(
        open_string(Content, In),
        load_html(In, DOM, []),
        close(In)).

%% extract_links(+DOM, -Links) - Extract all href links from HTML
extract_links(DOM, Links) :-
    findall(Href, xpath(DOM, //a(@href), Href), Links).

%% extract_text(+DOM, -Text) - Extract visible text content
%% Text inside <script> and <style> subtrees is filtered out.
%% (library(xpath) has no //text node test, so we walk the DOM.)
extract_text(DOM, Text) :-
    strip_script_style(DOM, CleanDOM),
    findall(T, dom_text(CleanDOM, T), Texts),
    atomic_list_concat(Texts, ' ', Text).

%% dom_text(+DOMList, -Text) is nondet
%% Yield each text-node atom/string in a DOM list.
dom_text([Node|Rest], Text) :-
    (   (atom(Node) ; string(Node)),
        Text = Node
    ;   Node = element(_, _, Children),
        dom_text(Children, Text)
    ;   Rest \= [],
        dom_text(Rest, Text)
    ).
```

The `fetch_page/2` predicate requests the page with the `to(string)` option so the body comes back as a Prolog string, sets a 20 second timeout and a custom `User-Agent`, and requests the HTTP status code. The call sits inside `catch/3`; a transport error or a non-200 status prints a warning and fails. `parse_html_dom/2` then opens the string as a stream with `open_string/2` and hands it to `load_html/3`.

The `extract_links/2` predicate uses `findall/3` with `xpath/3` to collect results: the XPath expression `//a(@href)` selects all `<a>` elements and extracts their `href` attribute. `extract_text/2` is different: because `library(xpath)` has no `//text` node test, it first removes `<script>` and `<style>` subtrees with `strip_script_style/2`, then walks the DOM with `dom_text/2` to yield each text node.

{width: "80%"}
![Architecture diagram for the Web Scraper example](FIG_web_scraper.jpg)

## Practical Applications

These HTTP client and scraping building blocks are used throughout the book:

- **LLM API Integration** - The `rest_client` module is the foundation for calling the Google Gemini and Ollama APIs (see the LLM Integration chapter). A single `http_post_json/3` call sends a prompt and receives the model's response.
- **SPARQL Queries** - The Semantic Web chapter uses HTTP GET requests to query remote SPARQL endpoints like DBpedia and Wikidata, parsing the JSON results into Prolog terms for local reasoning.
- **Knowledge Graph Enrichment** - Web scraping can extract structured data from HTML pages and assert it into a local knowledge graph. For example, scraping a product catalogue and converting the extracted attributes into `entity/3` facts.
- **Data Pipeline Preprocessing** - Fetching CSV or JSON datasets from public APIs (such as government open data portals) and transforming them into Prolog facts for analysis with the anomaly detection or probabilistic reasoning modules.

## Optional Practice Problems

1. **Image Link Scraper**: In the `web_scraper` project, extend `scraper.pl` to parse and extract the `src` attribute of all `<img>` tags on a webpage, handling relative paths correctly.
2. **HTTP Retry Decorator**: In `http_client`, implement a wrapper predicate `http_get_retry/3` that automatically retries an HTTP request up to three times with exponential backoff if the server returns a temporary network code.
