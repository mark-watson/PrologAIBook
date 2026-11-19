:- module(test_categorizer, []).
:- use_module(library(plunit)).
:- use_module('../prolog/categorizer').
:- use_module('../prolog/summarizer').

:- begin_tests(categorizer).

test(politics_first) :-
    categorize([president, election, vote, market], Cats),
    assertion(Cats = [3-politics, 1-economy]).

test(plural_matches_singular) :-
    keyword_count([startups, algorithms], [startup, algorithm], N),
    assertion(N == 2).

test(two_word_keyword) :-
    categorize([the, interest, rate, rose], Cats),
    assertion(memberchk(_-economy, Cats)).

test(case_insensitive) :-
    categorize(['Doctor', 'Hospital'], Cats),
    assertion(Cats == [2-healthcare]).

test(no_keywords) :-
    categorize([the, cat, sat], Cats),
    assertion(Cats == []).

test(no_duplicate_keywords) :-
    forall(category_words(C, Ws),
           ( sort(Ws, Set), length(Ws, N), length(Set, N)
           -> true ; fail(C) )).

:- end_tests(categorizer).

:- begin_tests(summarizer).

sentences([ [the, hospital, installed, a, new, software, database, system],
            [technology, startups, are, building, quantum, encryption,
             algorithms],
            [cats, and, dogs, run, in, the, local, park] ]).

test(top_two_technology) :-
    sentences(S),
    summarize(S, technology, Summary),
    assertion(Summary == [
        [technology, startups, are, building, quantum, encryption,
         algorithms],
        [the, hospital, installed, a, new, software, database, system]]).

test(top_one_healthcare) :-
    sentences(S),
    summarize(S, healthcare, 1, Summary),
    assertion(Summary == [[the, hospital, installed, a, new, software,
                           database, system]]).

test(no_match_gives_empty) :-
    summarize([[cats, run]], politics, Summary),
    assertion(Summary == []).

:- end_tests(summarizer).
