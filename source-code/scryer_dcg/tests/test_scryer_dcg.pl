:- module(test_scryer_dcg, [run_tests/0]).

:- set_prolog_flag(double_quotes, chars).

:- use_module('../prolog/text_dcg').


%% Simple test runner for Scryer Prolog (no plunit)
run_tests :-
    test_csv_parse,
    test_key_value,
    write('All scryer_dcg tests passed'), nl.

test_csv_parse :-
    parse_csv_line("hello,world,test", Fields),
    Fields = [hello, world, test],
    write('  csv_parse: passed'), nl, !.

test_key_value :-
    parse_key_value("name=Mark", Pair),
    Pair = name-'Mark',
    write('  key_value: passed'), nl, !.
