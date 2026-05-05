# Examples Using Scryer Prolog (The Modern Wave)

Scryer Prolog is a modern Prolog implementation written in Rust that aims for strict ISO compliance and efficient memory usage. Its standout feature is an incredibly memory-efficient representation of strings, making Definite Clause Grammars highly practical for processing large volumes of text.

## Why Scryer Prolog?

TBD: The design philosophy of Scryer Prolog. ISO compliance, memory efficiency, and the Rust foundation. When to choose Scryer over SWI-Prolog.

## Installing Scryer Prolog

TBD: Building from source with Cargo. Platform-specific notes.

## Differences from SWI-Prolog

TBD: Key differences developers should be aware of — module system, built-in predicates, library availability, and string handling.

## DCG Processing of Large Text with Scryer

TBD: Taking advantage of Scryer's memory-efficient string representation to process large text files with DCGs. A practical NLP example that would be impractical in other Prolog systems.

The **scryer_dcg** project demonstrates text processing DCGs designed for Scryer. Here is the file **scryer_dcg/prolog/text_dcg.pl**:

```prolog
%% text_dcg.pl - Efficient text processing with Scryer Prolog's DCGs
:- module(text_dcg, [
    parse_csv_line/2, parse_key_value/2, extract_emails/2
]).

%% parse_csv_line(+Line, -Fields)
parse_csv_line(Line, Fields) :-
    phrase(csv_line(Fields), Line).

csv_line([Field|Fields]) --> csv_field(Field), ",", csv_line(Fields).
csv_line([Field]) --> csv_field(Field).

csv_field(Field) --> "\"", quoted_chars(Chars), "\"",
    { atom_chars(Field, Chars) }.
csv_field(Field) --> unquoted_chars(Chars),
    { atom_chars(Field, Chars) }.

quoted_chars([C|Cs]) --> [C], { C \= '"' }, quoted_chars(Cs).
quoted_chars([]) --> [].

unquoted_chars([C|Cs]) --> [C], { C \= ',', C \= '\n' },
                           unquoted_chars(Cs).
unquoted_chars([]) --> [].

%% parse_key_value(+String, -Pair)
parse_key_value(String, Key-Value) :-
    phrase(kv_pair(Key, Value), String).

kv_pair(Key, Value) --> word(KeyChars), "=", rest(ValChars),
    { atom_chars(Key, KeyChars), atom_chars(Value, ValChars) }.

word([C|Cs]) --> [C], { C \= '=' }, word(Cs).
word([]) --> [].

rest([C|Cs]) --> [C], rest(Cs).
rest([]) --> [].
```

## Constraint Logic Programming in Scryer

TBD: Using Scryer's CLP libraries. Comparing the experience with SWI-Prolog's CLP.

The **scryer_clp** project contains CLP(Z) examples targeting Scryer Prolog. Here is the file **scryer_clp/prolog/scryer_constraints.pl**:

```prolog
%% scryer_constraints.pl - CLP examples targeting Scryer Prolog
:- module(scryer_constraints, [magic_square/1, send_more_money/1]).

:- use_module(library(clpz)).  % Scryer uses clpz, not clpfd

%% magic_square(-Square) - Solve a 3x3 magic square
magic_square(Square) :-
    Square = [A,B,C,D,E,F,G,H,I],
    Square ins 1..9,
    all_different(Square),
    Sum #= 15,
    A + B + C #= Sum, D + E + F #= Sum, G + H + I #= Sum,
    A + D + G #= Sum, B + E + H #= Sum, C + F + I #= Sum,
    A + E + I #= Sum, C + E + G #= Sum,
    label(Square).

%% send_more_money(-Letters) - Classic cryptarithmetic puzzle
send_more_money([S,E,N,D,M,O,R,Y]) :-
    Digits = [S,E,N,D,M,O,R,Y],
    Digits ins 0..9,
    all_different(Digits),
    S #\= 0, M #\= 0,
                 1000*S + 100*E + 10*N + D
    +            1000*M + 100*O + 10*R + E
    #= 10000*M + 1000*O + 100*N + 10*E + Y,
    label(Digits).
```

Note: This module requires Scryer Prolog's `library(clpz)` and will not load under SWI-Prolog. The test suite skips the full CLP tests when running on SWI-Prolog.

## Porting SWI-Prolog Code to Scryer

TBD: Practical tips and common pitfalls when porting code between the two systems. A compatibility checklist.
