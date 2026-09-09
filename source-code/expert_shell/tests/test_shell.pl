:- module(test_shell, []).
:- use_module(library(plunit)).
:- use_module('../prolog/shell').

:- begin_tests(shell, [cleanup(reset_known)]).

test(default_unknown) :-
    consult_expert(Conclusion),
    Conclusion == unknown.

test(provide_answer_drives_kb) :-
    module_property(test_shell, file(TestFile)),
    file_directory_name(TestFile, TestDir),
    atomic_list_concat([TestDir, '/../prolog/sample_kb.pl'], KbFile0),
    absolute_file_name(KbFile0, KbFile),
    load_kb(KbFile),
    provide_answer(meal, red_meat),
    provide_answer(bold_preference, yes),
    consult_expert(Conclusion),
    Conclusion == serve_cabernet,
    reset_known.

test(provide_answer_cached) :-
    provide_answer(color, red),
    provide_answer(color, blue),
    findall(V, shell:known(color, V), Vs),
    Vs == [blue].

test(normalize_strips_dot) :-
    shell:normalize_answer("bicycle.", V1),
    V1 == bicycle.

test(normalize_number) :-
    shell:normalize_answer("42.", V2),
    V2 =:= 42.

:- end_tests(shell).
