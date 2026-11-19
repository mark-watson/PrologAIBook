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

kb_path(Name, Path) :-
    module_property(test_shell, file(TestFile)),
    file_directory_name(TestFile, TestDir),
    atomic_list_concat([TestDir, '/../prolog/', Name], Path0),
    absolute_file_name(Path0, Path).

test(readable_rules_fire) :-
    kb_path('rules_kb.pl', Kb),
    load_kb(Kb),
    reset_known,
    provide_answer(meal, fish),
    provide_answer(light_preference, no),
    consult_expert(C),
    assertion(C == serve_chardonnay),
    reset_known.

test(readable_rules_explain) :-
    kb_path('rules_kb.pl', Kb),
    load_kb(Kb),
    reset_known,
    provide_answer(meal, dessert),
    provide_answer(sweet_preference, yes),
    consult_expert(C),
    with_output_to(string(S), explain(C)),
    assertion(sub_string(S, _, _, _,
        "serve_port because meal is dessert and sweet_preference is yes")),
    reset_known.

test(rule_parses_to_conditions) :-
    shell:and_list(a is 1 and b is 2, Cs),
    assertion(Cs == [a == 1, b == 2]).

:- end_tests(shell).
