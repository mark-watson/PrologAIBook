:- module(test_sudoku, []).
:- use_module(library(plunit)).
:- use_module('../prolog/sudoku').

:- begin_tests(sudoku).

test(solve_simple_puzzle) :-
    Puzzle = [[5,3,_,_,7,_,_,_,_],
              [6,_,_,1,9,5,_,_,_],
              [_,9,8,_,_,_,_,6,_],
              [8,_,_,_,6,_,_,_,3],
              [4,_,_,8,_,3,_,_,1],
              [7,_,_,_,2,_,_,_,6],
              [_,6,_,_,_,_,2,8,_],
              [_,_,_,4,1,9,_,_,5],
              [_,_,_,_,8,_,_,7,9]],
    sudoku(Puzzle),
    append(Puzzle, Flat),
    msort(Flat, _),  % all should be ground
    maplist(ground, Flat).

:- end_tests(sudoku).
