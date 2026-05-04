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
