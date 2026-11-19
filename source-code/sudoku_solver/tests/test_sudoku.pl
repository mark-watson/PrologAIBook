:- module(test_sudoku, []).
:- use_module(library(plunit)).
:- use_module(library(clpfd)).
:- use_module('../prolog/sudoku').
:- use_module('../prolog/send_more').

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
    valid_sudoku(Puzzle).

test(prints_dots_for_unsolved) :-
    with_output_to(
        atom(Output),
        print_board([[a,1,_,_,_,_,_,_,_]])),
    sub_atom(Output, _, _, _, '.'),
    sub_atom(Output, _, _, _, '1'),
    !.

test(contradictory_puzzle, [fail]) :-
    % Two 5s in the first row.
    Puzzle = [[5,5,_,_,_,_,_,_,_]|Rest],
    length(Rest, 8),
    sudoku(Puzzle).

test(send_more_money, all(D == [[9,5,6,7,1,0,8,2]])) :-
    send_more(D).

:- end_tests(sudoku).

%% valid_sudoku(+Rows) - every row, column and 3x3 box of a
%% solved Sudoku board contains exactly the digits 1..9.
valid_sudoku(Rows) :-
    maplist(digits_1_to_9, Rows),
    transpose(Rows, Columns),
    maplist(digits_1_to_9, Columns),
    Rows = [R1,R2,R3,R4,R5,R6,R7,R8,R9],
    box_group(R1, R2, R3),
    box_group(R4, R5, R6),
    box_group(R7, R8, R9).

%% box_group(+R1, +R2, +R3) - three consecutive rows: each
%% 3x3 box must contain the digits 1..9.
box_group([], [], []).
box_group([A,B,C|Rest1], [D,E,F|Rest2], [G,H,I|Rest3]) :-
    digits_1_to_9([A,B,C,D,E,F,G,H,I]),
    box_group(Rest1, Rest2, Rest3).

digits_1_to_9(Cells) :-
    msort(Cells, [1,2,3,4,5,6,7,8,9]).
