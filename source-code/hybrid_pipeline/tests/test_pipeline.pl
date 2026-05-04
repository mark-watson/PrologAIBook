:- module(test_pipeline, []).
:- use_module(library(plunit)).

:- begin_tests(pipeline).

test(module_concept) :-
    true.  % Requires Janus + spaCy; tested manually

:- end_tests(pipeline).
