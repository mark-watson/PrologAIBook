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

%% CSV grammar limitations: this parser handles plain and double-quoted
%% fields, but NOT escaped quotes ("" inside a quoted field) and NOT
%% CRLF line endings (line input is assumed to be split already, with
%% '\n' treated as a field terminator, not '\r\n').

%% extract_emails(+Text, -Emails)
%% DCG-based email extraction from text.  Emails match
%% local@domain where local/domain use letters, digits, '.', '_', '-'
%% (this is NOT full RFC 5322, just the common simple form).
extract_emails(Text, Emails) :-
    phrase(emails(Emails), Text),
    !.

emails([]) --> eos.
emails([Email|Emails]) -->
    email(EmailChars),
    { atom_chars(Email, EmailChars) },
    !, emails(Emails).
emails(Emails) --> [_], emails(Emails).

%% email//1 matches local@domain with at least one local char and
%% at least one domain char on each side of '@'.
email(Email) -->
    local_chars(Local), "@", domain_chars(Domain),
    { Local \= [], Domain \= [],
      append(Local, ['@'|Domain], Email) }.

local_chars([C|Cs]) --> [C], { local_char(C) }, local_chars(Cs).
local_chars([]) --> "".

local_char(C) :- char_type(C, alnum) ; C = '.' ; C = '_' ; C = '-'.

domain_chars([C|Cs]) --> [C], { domain_char(C) }, domain_chars(Cs).
domain_chars([]) --> "".

domain_char(C) :- char_type(C, alnum) ; C = '.' ; C = '-'.

eos([], []).

