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

%% strip_script_style(+DOM, -CleanDOM)
%% Recursively remove script and style subtrees from a DOM list.
strip_script_style(DOM, CleanDOM) :-
    strip_ss(DOM, CleanDOM).

strip_ss([], []).
strip_ss([Element|Rest], Clean) :-
    Element = element(Name, _, _),
    memberchk(Name, [script, style]),
    !,
    strip_ss(Rest, Clean).
strip_ss([element(Name, Attrs, Children)|Rest],
         [element(Name, Attrs, CleanChildren)|CleanRest]) :-
    !,
    strip_ss(Children, CleanChildren),
    strip_ss(Rest, CleanRest).
strip_ss([Other|Rest], [Other|CleanRest]) :-
    strip_ss(Rest, CleanRest).

:- multifile prolog:message//1.

prolog:message(scraper_error(transport(URL, Error))) -->
    ['scraper: failed to fetch ~w: ~w'-[URL, Error]].
prolog:message(scraper_error(status(URL, Code))) -->
    ['scraper: ~w returned HTTP status ~w'-[URL, Code]].
