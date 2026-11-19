%% summarizer.pl - Extractive summarization with category keywords
:- module(summarizer, [
    summarize/3,
    summarize/4
]).

:- use_module(categorizer, [category_words/2, keyword_count/3]).

%% summarize(+Sentences, +Category, -Summary)
%% Summary holds the two sentences that best match Category.
summarize(Sentences, Category, Summary) :-
    summarize(Sentences, Category, 2, Summary).

%% summarize(+Sentences, +Category, +N, -Summary)
%% Sentences is a list of word lists. Summary holds up to N of them,
%% highest keyword count first. Sentences with no matches are left
%% out. Ties keep their order in the input.
summarize(Sentences, Category, N, Summary) :-
    category_words(Category, Keywords),
    findall(Score-S,
            (   member(S, Sentences),
                keyword_count(S, Keywords, Score),
                Score > 0
            ),
            Scored),
    sort(1, @>=, Scored, Sorted),
    length(Sorted, Len),
    Take is min(N, Len),
    length(Top, Take),
    append(Top, _, Sorted),
    pairs_values(Top, Summary).
