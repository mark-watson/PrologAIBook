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
