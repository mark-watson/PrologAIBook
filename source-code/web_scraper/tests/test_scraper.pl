:- module(test_scraper, []).
:- use_module(library(plunit)).
:- use_module('../prolog/scraper').

offline_html(
    '<html><head><title>T</title><style>p{color:red}</style></head>
     <body>
       <h1>Main heading</h1>
       <p>First paragraph</p>
       <a href="https://example.com/one">link one</a>
       <a href="/two">link two</a>
       <script>var secret = "script text";</script>
       <p>Last paragraph</p>
     </body></html>').

:- begin_tests(scraper).

test(parse_html_dom_links) :-
    offline_html(Html),
    parse_html_dom(Html, DOM),
    extract_links(DOM, Links),
    assertion(Links == ['https://example.com/one', '/two']).

test(extract_text_includes_visible_text) :-
    offline_html(Html),
    parse_html_dom(Html, DOM),
    extract_text(DOM, Text),
    forall(
        member(T, ["Main heading", "First paragraph",
                   "Last paragraph"]),
        assertion(sub_string(Text, _, _, _, T))).

test(extract_text_excludes_script_and_style) :-
    offline_html(Html),
    parse_html_dom(Html, DOM),
    extract_text(DOM, Text),
    assertion(\+ sub_string(Text, _, _, _, "script text")),
    assertion(\+ sub_string(Text, _, _, _, "color:red")).

test(strip_script_style_removes_subtrees) :-
    DOM = [element(body, [], ['keep',
                              element(script, [], ['drop']),
                              element(style, [], ['drop too'])])],
    strip_script_style(DOM, Clean),
    assertion(Clean == [element(body, [], ['keep'])]).

:- end_tests(scraper).
