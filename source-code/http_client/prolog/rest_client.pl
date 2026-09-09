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

:- multifile prolog:message//1.

prolog:message(http_client_error(Error)) -->
    ['rest_client: HTTP request failed: ~w'-[Error]].
