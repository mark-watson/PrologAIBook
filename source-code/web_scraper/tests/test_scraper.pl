:- module(test_scraper, []).
:- use_module(library(plunit)).
:- use_module('../prolog/scraper').

:- begin_tests(scraper).

test(module_loads) :-
    true.  % Live web tests done manually

:- end_tests(scraper).
