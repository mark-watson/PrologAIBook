# Web Clients in Prolog

SWI-Prolog includes comprehensive HTTP client libraries that make it straightforward to interact with REST APIs, parse JSON, and scrape web content — all from within Prolog.

{width: "80%"}
![Architecture diagram for the HTTP Client example](FIG_http_client.jpg)

{width: "80%"}
![Architecture diagram for the Web Scraper example](FIG_web_scraper.jpg)

## HTTP GET and POST Requests

TBD: Using `library(http/http_client)` for making HTTP requests. Headers, authentication, and error handling.

The **http_client** project wraps SWI-Prolog's HTTP libraries. Here is the file **http_client/prolog/rest_client.pl**:

```prolog
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
```

## Working with JSON

TBD: Parsing JSON responses into Prolog dicts. Traversing nested structures. Converting between JSON and Prolog terms.

The **http_client** project also includes JSON utilities. Here is the file **http_client/prolog/json_utils.pl**:

```prolog
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

## Web Scraping

TBD: Loading web pages, parsing HTML with SWI-Prolog's SGML library, and extracting structured data.

## Practical Applications

TBD: Building a Prolog-based REST API consumer. Combining web data with local reasoning.
