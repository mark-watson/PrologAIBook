%% scryer_constraints.pl - CLP examples targeting Scryer Prolog
%% Demonstrates Scryer's CLP(Z) (integers) library
:- module(scryer_constraints, [
    magic_square/1,
    send_more_money/1
]).

:- use_module(library(clpz)).  % Scryer uses clpz, not clpfd

%% magic_square(-Square) - Solve a 3x3 magic square
magic_square(Square) :-
    Square = [A,B,C,D,E,F,G,H,I],
    Square ins 1..9,
    all_different(Square),
    Sum #= 15,
    A + B + C #= Sum,
    D + E + F #= Sum,
    G + H + I #= Sum,
    A + D + G #= Sum,
    B + E + H #= Sum,
    C + F + I #= Sum,
    A + E + I #= Sum,
    C + E + G #= Sum,
    label(Square).

%% send_more_money(-Letters) - Classic cryptarithmetic puzzle
%%   S E N D
%% + M O R E
%% ---------
%% M O N E Y
send_more_money([S,E,N,D,M,O,R,Y]) :-
    Digits = [S,E,N,D,M,O,R,Y],
    Digits ins 0..9,
    all_different(Digits),
    S #\= 0, M #\= 0,
                 1000*S + 100*E + 10*N + D
    +            1000*M + 100*O + 10*R + E
    #= 10000*M + 1000*O + 100*N + 10*E + Y,
    label(Digits).
