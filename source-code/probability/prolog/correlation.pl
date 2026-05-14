%% correlation.pl — Correlation helpers
%%
%% NOTE: Correlation measures *association*, NOT causation.
%% A high |r| between X and Y does not imply that X causes Y,
%% that Y causes X, or even that they share a direct mechanism.
%% Confounders, selection bias, and reverse causation are always
%% possible.  Use these statistics as descriptive summaries, not
%% as evidence of causal relationships.

:- module(correlation, [
    pearson_r/3,
    spearman_rho/3,
    correlation_matrix/2,
    list_mean/2,
    list_std_dev/2
]).

:- use_module(library(lists)).
:- use_module(library(apply)).

%% ---------- utilities -----------------------------------------------

%% list_mean(+Xs, -Mean)
list_mean(Xs, Mean) :-
    sumlist(Xs, Sum),
    length(Xs, N),
    Mean is Sum / N.

%% list_std_dev(+Xs, -StdDev)
%% Population standard deviation.
list_std_dev(Xs, SD) :-
    list_mean(Xs, M),
    maplist(sq_diff(M), Xs, Diffs),
    sumlist(Diffs, SS),
    length(Xs, N),
    SD is sqrt(SS / N).

sq_diff(M, X, D) :- D is (X - M) * (X - M).

%% rank_list(+Xs, -Ranks)
%% Assign 1-based ranks with averaged ties.
rank_list(Xs, Ranks) :-
    length(Xs, N),
    N1 is N - 1,
    numlist(0, N1, Indices),
    maplist(pair_val_idx, Xs, Indices, Indexed),
    msort(Indexed, Sorted),
    assign_ranks(Sorted, 0, N, RankPairs),
    sort(2, @=<, RankPairs, ByIdx),
    maplist(rank_pair_value, ByIdx, Ranks).

pair_val_idx(V, I, V-I).

rank_pair_value(R-_, R).

%% assign_ranks(+Sorted, +Pos, +N, -RankPairs)
%% Walk sorted list, grouping ties and assigning average ranks.
assign_ranks([], _, _, []).
assign_ranks([V-I|Rest], Pos, N, Result) :-
    collect_ties(V, Rest, [I], Indices, Remaining),
    length(Indices, GroupLen),
    EndPos is Pos + GroupLen,
    AvgRank is (Pos + 1 + EndPos) / 2.0,
    maplist(make_rank_pair(AvgRank), Indices, Pairs),
    append(Pairs, RestResult, Result),
    assign_ranks(Remaining, EndPos, N, RestResult).

collect_ties(V, [V-I2|Rest], Acc, Indices, Remaining) :-
    !,
    collect_ties(V, Rest, [I2|Acc], Indices, Remaining).
collect_ties(_, Rest, Acc, Indices, Rest) :-
    reverse(Acc, Indices).

make_rank_pair(Rank, Idx, Rank-Idx).

%% ---------- Pearson r -----------------------------------------------

%% pearson_r(+Xs, +Ys, -R)
%% Pearson product-moment correlation coefficient.
%% WARNING: measures linear association only — not causation.
pearson_r(Xs, Ys, R) :-
    length(Xs, N),
    length(Ys, N),   % assert equal length
    list_mean(Xs, MX),
    list_mean(Ys, MY),
    list_std_dev(Xs, SX),
    list_std_dev(Ys, SY),
    (   (SX =:= 0 ; SY =:= 0)
    ->  R = 0.0
    ;   maplist(cross_dev(MX, MY), Xs, Ys, Prods),
        sumlist(Prods, SumProd),
        R is SumProd / (N * SX * SY)
    ).

cross_dev(MX, MY, X, Y, P) :-
    P is (X - MX) * (Y - MY).

%% ---------- Spearman ρ -----------------------------------------------

%% spearman_rho(+Xs, +Ys, -Rho)
%% Spearman rank-order correlation coefficient.
%% Converts to ranks then computes Pearson-r on the ranks.
%% WARNING: measures monotonic association only — not causation.
spearman_rho(Xs, Ys, Rho) :-
    rank_list(Xs, RXs),
    rank_list(Ys, RYs),
    pearson_r(RXs, RYs, Rho).

%% ---------- correlation matrix --------------------------------------

%% correlation_matrix(+DataAlist, -Matrix)
%% DataAlist is a list of Name-Values pairs.
%% Matrix is a list of (NameA-NameB)-R triples.
correlation_matrix(DataAlist, Matrix) :-
    findall((NA-NB)-R,
            (member(NA-ValsA, DataAlist),
             member(NB-ValsB, DataAlist),
             pearson_r(ValsA, ValsB, R)),
            Matrix).
