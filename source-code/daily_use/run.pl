%% run.pl — Bootstrap and launch the daily-use REPL
%%
%% Usage:  swipl run.pl

:- use_module('../cache_engine/prolog/cache_engine').
:- use_module(prolog/daily_use).

:- initialization(main, main).
