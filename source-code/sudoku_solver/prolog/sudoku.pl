%% sudoku.pl - Sudoku solver using CLP(FD) constraints
:- module(sudoku, [
    sudoku/1,
    print_board/1
]).

:- use_module(library(clpfd)).

%% sudoku(+Rows) - Solve a 9x9 Sudoku puzzle
%% Rows is a list of 9 lists, each containing 9 elements (vars or 1-9)
sudoku(Rows) :-
    length(Rows, 9),
    maplist(same_length(Rows), Rows),
    append(Rows, Vs), Vs ins 1..9,
    maplist(all_distinct, Rows),
    transpose(Rows, Columns),
    maplist(all_distinct, Columns),
    Rows = [As,Bs,Cs,Ds,Es,Fs,Gs,Hs,Is],
    blocks(As, Bs, Cs),
    blocks(Ds, Es, Fs),
    blocks(Gs, Hs, Is),
    maplist(label, Rows).

blocks([], [], []).
blocks([N1,N2,N3|Ns1], [N4,N5,N6|Ns2], [N7,N8,N9|Ns3]) :-
    all_distinct([N1,N2,N3,N4,N5,N6,N7,N8,N9]),
    blocks(Ns1, Ns2, Ns3).

%% print_board(+Rows) - Pretty-print a solved board
print_board([]).
print_board([Row|Rows]) :-
    format("~w~n", [Row]),
    print_board(Rows).
