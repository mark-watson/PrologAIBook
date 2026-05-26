:- module(test_pipeline, []).
:- use_module(library(plunit)).
:- use_module(prolog/pipeline).

:- begin_tests(pipeline).

test(run_pipeline_success) :-
    run_pipeline("John Smith visited London last week", Result),
    Result = pipeline_result(_, Conclusions),
    % Verify that we extracted both an important person and a location
    member(conclusion(_, important_person), Conclusions),
    member(conclusion(_, location), Conclusions),
    !.

:- end_tests(pipeline).
