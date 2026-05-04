%% categorizer.pl - Simple bag-of-words text categorization
:- module(categorizer, [
    categorize/2
]).

%% Category keyword weights
category_words(politics, [president, congress, election, vote, senator, law, government, political]).
category_words(sports, [game, team, player, score, win, tournament, match, championship]).
category_words(technology, [computer, software, algorithm, data, programming, internet, digital, code]).
category_words(economy, [market, stock, trade, bank, money, economy, financial, tax, debt]).

%% categorize(+WordList, -Categories)
%% Returns list of category-score pairs, sorted by score descending
categorize(Words, Categories) :-
    findall(
        Score-Category,
        (   category_words(Category, Keywords),
            score_category(Words, Keywords, Score),
            Score > 0
        ),
        Pairs
    ),
    sort(1, @>=, Pairs, Categories).

score_category(Words, Keywords, Score) :-
    include(word_in_list(Keywords), Words, Matches),
    length(Matches, Score).

word_in_list(Keywords, Word) :-
    downcase_atom(Word, Lower),
    member(Lower, Keywords).
