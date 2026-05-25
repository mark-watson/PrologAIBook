%% NOTE: This project is for Scryer Prolog, not SWI-Prolog
%% The scryer_constraints module uses library(clpz) which is only
%% available in Scryer Prolog. On SWI-Prolog we skip loading.
:- if(exists_source(library(clpz))).
:- use_module(prolog/scryer_constraints).
:- else.
:- format('Note: scryer_clp requires Scryer Prolog'),
   format(' (clpz not available)~n').
:- endif.
