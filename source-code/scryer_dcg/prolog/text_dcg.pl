%% text_dcg.pl - Efficient text processing with Scryer Prolog's DCGs
%% Scryer's memory-efficient string representation makes this practical
%% for large-scale text processing
:- module(text_dcg, [
    parse_csv_line/2,
    parse_key_value/2,
    extract_emails/2
]).

:- set_prolog_flag(double_quotes, chars).


%% parse_csv_line(+Line, -Fields)
%% Parse a CSV line into a list of fields
parse_csv_line(Line, Fields) :-
    phrase(csv_line(Fields), Line).

csv_line([Field|Fields]) --> csv_field(Field), ",", csv_line(Fields).
csv_line([Field]) --> csv_field(Field).

csv_field(Field) --> "\"", quoted_chars(Chars), "\"",
    { atom_chars(Field, Chars) }.
csv_field(Field) --> unquoted_chars(Chars),
    { atom_chars(Field, Chars) }.

quoted_chars([C|Cs]) --> [C], { C \= ('"') }, quoted_chars(Cs).
quoted_chars([]) --> [].

unquoted_chars([C|Cs]) --> [C], { C \= (','), C \= ('\n') },
    unquoted_chars(Cs).
unquoted_chars([]) --> [].

%% parse_key_value(+String, -Pair)
parse_key_value(String, Key-Value) :-
    phrase(kv_pair(Key, Value), String).

kv_pair(Key, Value) --> word(KeyChars), "=", rest(ValChars),
    { atom_chars(Key, KeyChars), atom_chars(Value, ValChars) }.

word([C|Cs]) --> [C], { C \= ('=') }, word(Cs).
word([]) --> [].

rest([C|Cs]) --> [C], rest(Cs).
rest([]) --> [].

%% extract_emails(+Text, -Emails)
%% TBD: DCG-based email extraction from text
extract_emails(_Text, []).
