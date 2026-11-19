%% send_more.pl - The SEND + MORE = MONEY puzzle in CLP(FD)
:- module(send_more, [
    send_more/1
]).

:- use_module(library(clpfd)).

%% send_more(-Digits)
%% Digits = [S,E,N,D,M,O,R,Y]: distinct digits, no leading zero,
%% such that SEND + MORE = MONEY.
send_more(Digits) :-
    Digits = [S,E,N,D,M,O,R,Y],
    Digits ins 0..9,
    all_different(Digits),
    S #\= 0,
    M #\= 0,
                1000*S + 100*E + 10*N + D
              + 1000*M + 100*O + 10*R + E
    #= 10000*M + 1000*O + 100*N + 10*E + Y,
    label(Digits).
