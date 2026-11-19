# Web Clients in Prolog

SWI-Prolog's HTTP client libraries let a Prolog program call REST APIs, parse JSON, and scrape web pages.

{width: "80%"}
![Architecture diagram for the HTTP Client example](FIG_http_client.jpg)

## HTTP GET and POST Requests

`library(http/http_client)` is an HTTP/1.1 client for GET, POST, PUT, and DELETE requests, over HTTP or HTTPS. `library(http/http_json)` adds JSON conversion, so one `http_get/3` call can fetch a URL and return its JSON body as a Prolog dict.

The key predicates are:
- **`http_get(+URL, -Reply, +Options)`** sends a GET request. The `json_object(dict)` option returns a JSON body as a dict instead of the older `json/1` term.
- **`http_post(+URL, +Data, -Reply, +Options)`** sends a POST request. `Data` can be `atom(Body)`, `json(Term)`, and other forms. Request headers such as `Authorization` go in the options.

By default, a reply with an error status raises an exception. A 404, for example, raises `existence_error(url, URL)`. If you pass the option `status_code(Code)`, the library raises no exception and binds `Code`, so your code can decide what to do.

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

`http_get_json/2` adds the `json_object(dict)` option. `http_post_json/3` sends the payload as `json(Payload)`, which the library serializes, and parses the JSON reply into a dict. Both pass `status_code(Code)`, and `wrapped_call/2` turns a network error or a status outside 200 to 299 into a warning and a failure. The versions with an Options argument pass extra options to `http_get/3` and `http_post/4`.

Try it in the REPL (this needs network access):

```prolog
?- http_get_json('https://jsonplaceholder.typicode.com/todos/1', R).
R = #{completed:false, id:1, title:"delectus aut autem", userId:1}.

?- http_get_json('https://jsonplaceholder.typicode.com/todos/0', R).
Warning: rest_client: HTTP request failed: bad_status(404)
false.
```

SWI-Prolog 10 gives dicts read from JSON the tag `#`, so they print as `#{...}`. Older versions leave the tag unbound and print `_{...}`. The tag does not affect your code.

## Working with JSON

Most web APIs return JSON. SWI-Prolog has two ways to represent it:
1. **Dicts** (the modern way): key-value maps read with dot notation (e.g., `Dict.name`). They match JSON objects and are the recommended form.
2. **`json/1` terms** (the older way): `json([key=value, ...])`. Still supported, but harder to use.

`atom_json_dict/3` converts between JSON text and a dict, in either direction:

```prolog
%% Parsing: JSON string -> Prolog dict
?- atom_json_dict('{"name":"Alice","age":30}', Dict, []).
Dict = #{age:30, name:"Alice"}.

%% Generating: Prolog dict -> JSON string
?- atom_json_dict(Json, _{name:"Bob", score:95}, []).
Json = '{"name":"Bob","score":95}'.
```

For nested JSON, chain the dots: `Dict.address.city` reads the `city` field of a nested `address` object. A JSON array becomes a Prolog list. Dot notation works in clauses and at the REPL, which expand it when they are read; in a goal built at run time, such as one passed to `swipl -g`, use `get_dict/3` instead.

Here is the file **http_client/prolog/json_utils.pl**:

```prolog
%% json_utils.pl - JSON parsing and generation utilities
:- module(json_utils, [
    parse_json_string/2,
    json_dict_pairs/2,
    dict_to_json_string/2
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

%% dict_to_json_string(+Dict, -JsonString)
%% Serialize a dict as compact JSON text.
dict_to_json_string(Dict, JsonString) :-
    atom_json_dict(Atom, Dict, [width(0)]),
    atom_string(Atom, JsonString).
```

`json_dict_pairs/2` uses `dict_pairs/3` to split a dict into `Key-Value` pairs, which lets you loop over every field without knowing the keys. `dict_to_json_string/2` goes the other way; the `width(0)` option writes the JSON on one line.

## Web Scraping

SWI-Prolog can also fetch and parse HTML pages, using three libraries:
1. **`library(http/http_client)`** fetches the HTML from a URL.
2. **`library(sgml)`** parses the HTML into a DOM tree: nested `element(Name, Attributes, Children)` terms.
3. **`library(xpath)`** selects parts of the tree with XPath-like expressions.

`load_html/3` copes with malformed HTML, which real pages often contain. With a DOM tree, `xpath(DOM, //a(@href), Href)` returns the `href` attribute of every `<a>` element in turn.

Here is the main part of **web_scraper/prolog/scraper.pl** (the rest of the file is `strip_script_style/2`, which copies the DOM without its `script` and `style` elements):

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
%% Text inside <script> and <style> subtrees is filtered out, and each
%% text node has its white space collapsed. (library(xpath) has no
%% //text node test, so we walk the DOM.)
extract_text(DOM, Text) :-
    strip_script_style(DOM, CleanDOM),
    findall(T, ( dom_text(CleanDOM, T0),
                 normalize_space(atom(T), T0),
                 T \== '' ),
            Texts),
    atomic_list_concat(Texts, ' ', Text).

%% dom_text(+DOMList, -Text) is nondet
%% Yield each text node in a DOM list, depth first.
dom_text(Nodes, Text) :-
    member(Node, Nodes),
    (   atomic(Node)
    ->  Text = Node
    ;   Node = element(_, _, Children),
        dom_text(Children, Text)
    ).
```

`fetch_page/2` asks for the body as a string (`to(string)`), sets a 20-second timeout, sends a `User-Agent` header that names the program (polite scrapers identify themselves), and gets the status code. A network error or a status other than 200 prints a warning and fails. `parse_html_dom/2` opens the string as a stream with `open_string/2` for `load_html/3`.

`extract_links/2` collects every `href` with `findall/3` and `xpath/3`. `extract_text/2` works differently, since `library(xpath)` has no text node test. It removes `script` and `style` elements, walks the tree with `dom_text/2`, and collapses the white space in each text node with `normalize_space/2`, dropping nodes that hold only white space.

`make run` scrapes the SWI-Prolog home page (it needs network access):

```text
Found 17 links on swi-prolog.org
Text starts: SWI-Prolog Did you know ... Search Documentation: Robust,
mature, free. Prolog for the real world. HOME DOWNLOAD ...
```

Before you scrape a site, check its terms of use and its `robots.txt` file, and keep your request rate low.

{width: "80%"}
![Architecture diagram for the Web Scraper example](FIG_web_scraper.jpg)

## Practical Applications

These HTTP client and scraping building blocks are used throughout the book:

These building blocks appear throughout the book:

- **LLM APIs**: The LLM Integration chapter calls the Gemini and Ollama APIs with the same JSON-over-HTTP pattern: one POST sends a prompt and returns the model's reply.
- **SPARQL queries**: The Semantic Web chapter sends queries to DBpedia and Wikidata over HTTP and turns the results into Prolog terms.
- **Knowledge graph enrichment**: A scraper can pull structured data from HTML pages, such as product attributes from a catalog, and add it to a local knowledge graph as triples.
- **Data pipelines**: Fetch CSV or JSON data from public APIs, such as government open-data portals, and turn it into Prolog facts for analysis.

## Optional Practice Problems

1. **Image Sources**: In `web_scraper`, write `extract_images(+BaseURL, +DOM, -URLs)` that collects the `src` of every `<img>` and turns relative paths into absolute URLs. (Hint: `uri_resolve/3`.)
2. **Retry with Backoff**: In `http_client`, write `http_get_json_retry/3`, which retries a request up to three times, waiting 1, 2, and 4 seconds, when the status is 429 or 503.
3. **Headings Outline**: Write `outline(+DOM)` that prints the text of every `h1`, `h2`, and `h3` element, indented by level.
