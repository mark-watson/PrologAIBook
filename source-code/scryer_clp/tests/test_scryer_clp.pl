:- module(test_scryer_clp, [run_tests/0]).
:- use_module('../prolog/scryer_constraints').

%% Simple test runner for Scryer Prolog (no plunit)
run_tests :-
    test_magic_square,
    test_send_more_money,
    write('All scryer_clp tests passed'), nl.

test_magic_square :-
    magic_square([_,_,_,_,_,_,_,_,_]),
    write('  magic_square: passed'), nl, !.

test_send_more_money :-
    send_more_money([S,E,N,D,M,O,R,Y]),
    S =:= 9, E =:= 5, N =:= 6, D =:= 7,
    M =:= 1, O =:= 0, R =:= 8, Y =:= 2,
    write('  send_more_money: passed'), nl, !.
