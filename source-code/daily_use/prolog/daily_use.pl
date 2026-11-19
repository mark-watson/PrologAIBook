%% daily_use.pl - Interactive Gemini REPL with search grounding and
%% a cache of earlier answers
%%
%% Commands:
%%   <text>          Ask Gemini a question (plain, no search)
%%   !<text>         Ask Gemini with Google Search grounding
%%   >               Add last answer to the persistent cache
%%   !               Clear cache entries older than one week
%%   h / help        Show help
%%   q / quit / exit Exit the REPL
%%   Ctrl-D          Exit the REPL
%%
%% Copyright 2022-2026 Mark Watson. All rights reserved.

:- module(daily_use, [
    main/0,
    ask/3,
    extract_keywords/2,
    build_context_from_cache/3
]).

:- use_module(library(readutil)).
:- use_module('../../cache_engine/prolog/cache_engine').
:- use_module('../../llm_client/prolog/gemini').

%% ---- Configuration ----

model('gemini-2.5-flash').

%% cache_db_path(-Path)
%% The cache file, without its .db extension. Set DAILY_USE_CACHE to
%% use another file, for example a test cache.
cache_db_path(Path) :-
    (   getenv('DAILY_USE_CACHE', Path)
    ->  true
    ;   expand_file_name('~/.daily-use-cache', [Path])
    ).

%% ---- Mutable state ----

:- dynamic last_answer/1.
:- dynamic cache_connection/1.

%% ---- Stop words ----

stop_word(a).
stop_word(an).
stop_word(the).
stop_word(is).
stop_word(are).
stop_word(was).
stop_word(were).
stop_word(be).
stop_word(been).
stop_word(being).
stop_word(have).
stop_word(has).
stop_word(had).
stop_word(do).
stop_word(does).
stop_word(did).
stop_word(will).
stop_word(would).
stop_word(shall).
stop_word(should).
stop_word(may).
stop_word(might).
stop_word(must).
stop_word(can).
stop_word(could).
stop_word(am). stop_word(it). stop_word(its).
stop_word(in).
stop_word(on).
stop_word(at).
stop_word(to).
stop_word(for).
stop_word(of).
stop_word(with).
stop_word(by).
stop_word(from).
stop_word(as).
stop_word(and).
stop_word(or).
stop_word(but).
stop_word(not).
stop_word(no).
stop_word(nor). stop_word(so). stop_word(yet).
stop_word(this). stop_word(that). stop_word(these). stop_word(those).
stop_word(what). stop_word(which). stop_word(who). stop_word(whom).
stop_word(i).
stop_word(me).
stop_word(my).
stop_word(we).
stop_word(our).
stop_word(you).
stop_word(your).
stop_word(he).
stop_word(she).
stop_word(they).
stop_word(them).
stop_word(how). stop_word(when). stop_word(where). stop_word(why).
stop_word(if). stop_word(then). stop_word(than). stop_word(about).

%% ---- Keyword extraction ----

%% extract_keywords(+Text, -Keywords)
%% Splits text on whitespace, downcases, strips punctuation, removes
%% stop words and short words (length <= 2).
extract_keywords(Text, Keywords) :-
    downcase_atom(Text, Lower),
    atom_string(Lower, LowerStr),
    split_string(LowerStr, " \t\n", " \t\n", WordStrs),
    maplist(strip_punctuation, WordStrs, Cleaned),
    include(meaningful_word, Cleaned, MeaningfulStrs),
    maplist(atom_string_conv, MeaningfulStrs, Keywords).

%% strip_punctuation(+WordStr, -CleanStr)
strip_punctuation(Word, Clean) :-
    string_chars(Word, Chars),
    include(non_punct, Chars, CleanChars),
    string_chars(Clean, CleanChars).

non_punct(C) :-
    \+ member(C, ['?','!','.',',',';',':','"','\'','(',')','[',']','{',
        '}']).

meaningful_word(W) :-
    string_length(W, Len),
    Len > 2,
    atom_string(A, W),
    \+ stop_word(A).

atom_string_conv(S, A) :- atom_string(A, S).

%% ---- Cache context builder ----

%% build_context_from_cache(+Connection, +Query, -Context)
%% Context holds up to 10 cached answers that share a keyword with
%% Query, as a preamble for the prompt, or "" if none match.
build_context_from_cache(Connection, Query, Context) :-
    extract_keywords(Query, Keywords),
    (   Keywords == []
    ->  Items = []
    ;   cache_lookup(Connection, Keywords, Items,
                     [limit(10), match_any(true)])
    ),
    (   Items == []
    ->  Context = ""
    ;   format_context_items(Items, Formatted),
        format(string(Context),
               "Use the following context from previous conversations when answering:~n~n~w---~n~n",
               [Formatted])
    ).

format_context_items(Items, Formatted) :-
    findall(Line, ( member(Item, Items),
                    format(string(Line), "- ~w~n", [Item]) ),
            Lines),
    atomic_list_concat(Lines, Formatted).

%% ---- Asking Gemini ----

%% ask(+Question, +Search, -Answer)
%% Answer Question with Gemini, using cached answers as context.
%% Search is true to let Gemini use Google Search. Opens and closes
%% the cache, so it works outside the REPL too.
ask(Question, Search, Answer) :-
    cache_db_path(DbPath),
    setup_call_cleanup(
        cache_open(DbPath, Conn),
        ask_gemini(Conn, Question, Search, Answer),
        cache_close(Conn)).

%% ask_gemini(+Connection, +Question, +Search, -Answer)
%% On an API error, Answer is an error message instead.
ask_gemini(Connection, Question, Search, Answer) :-
    build_context_from_cache(Connection, Question, Context),
    string_concat(Context, Question, Prompt),
    model(Model),
    (   catch(gemini_generate(Prompt, Answer0,
                              [model(Model), search(Search)]),
              Error,
              error_answer(Error, Answer0))
    ->  Answer = Answer0
    ;   Answer = "[No response from Gemini: check the model name and API key]"
    ).

error_answer(Error, Text) :-
    message_to_string(Error, Msg),
    format(string(Text), "[Error calling Gemini: ~w]", [Msg]).

%% ---- Help text ----

print_help :-
    cache_connection(Conn),
    cache_count(Conn, N),
    cache_db_path(DbPath),
    model(Model),
    format("~n  Gemini Daily-Use REPL~n"),
    format("  -----------------------------------------~n"),
    format("  <text>         Ask Gemini a question~n"),
    format("  !<text>        Ask with Google Search grounding~n"),
    format("  >              Add last answer to cache~n"),
    format("  !              Clear cache entries older than 1 week~n"),
    format("  h / help       Show this help~n"),
    format("  q / quit       Exit~n"),
    format("  Ctrl-D         Exit~n"),
    format("  -----------------------------------------~n"),
    format("  Model: ~w~n", [Model]),
    format("  Cache: ~w.db (~w items)~n~n", [DbPath, N]).

%% ---- REPL ----

repl_loop :-
    format("~n  Gemini Daily-Use REPL  (type 'h' for help)~n~n"),
    repl_iteration.

%% repl_iteration
%% Read and handle one line, then loop. process_input/2 returns stop
%% for a quit command, so the loop ends normally and main/0 can close
%% the cache.
repl_iteration :-
    format("gemini> "),
    flush_output,
    read_line_to_string(current_input, Raw),
    (   Raw == end_of_file
    ->  format("~nGoodbye.~n")
    ;   normalize_space(atom(Input), Raw),
        process_input(Input, Next),
        (   Next == stop
        ->  format("Goodbye.~n")
        ;   repl_iteration
        )
    ).

%% process_input(+Input, -Next)
%% Handle one command. Next is stop to end the REPL, else continue.
process_input('', continue) :- !.
process_input(Q, stop) :-
    memberchk(Q, [q, quit, exit]), !.
process_input(H, continue) :-
    memberchk(H, [h, help]), !,
    print_help.
process_input('>', continue) :- !,
    (   last_answer(Ans)
    ->  cache_connection(Conn),
        cache_add(Conn, Ans),
        cache_count(Conn, N),
        format("  [Cached. ~w items total]~n", [N])
    ;   format("  [No answer to cache yet]~n")
    ).
process_input('!', continue) :- !,
    cache_connection(Conn),
    cache_count(Conn, Before),
    cache_clear_older_one_week(Conn),
    cache_count(Conn, After),
    Cleared is Before - After,
    format("  [Cleared ~w old entries. ~w items remain]~n",
           [Cleared, After]).
process_input(Input, continue) :-
    atom_concat('!', Rest, Input), !,
    normalize_space(atom(Query), Rest),
    format("  [Searching...]~n"),
    answer_and_show(Query, true).
process_input(Input, continue) :-
    format("  [Thinking...]~n"),
    answer_and_show(Input, false).

answer_and_show(Question, Search) :-
    flush_output,
    cache_connection(Conn),
    ask_gemini(Conn, Question, Search, Answer),
    format("~n~w~n~n", [Answer]),
    retractall(last_answer(_)),
    assertz(last_answer(Answer)).

%% ---- Entry point ----

%% main/0
%% Open the cache, run the REPL, and close the cache on the way out,
%% even if the REPL ends with an error.
main :-
    (   getenv('GOOGLE_API_KEY', _)
    ->  true
    ;   format("Error: GOOGLE_API_KEY environment variable is not set.~n"),
        format("Export it before running:  export GOOGLE_API_KEY=your-key-here~n"),
        halt(1)
    ),
    cache_db_path(DbPath),
    setup_call_cleanup(
        ( cache_open(DbPath, Conn),
          retractall(cache_connection(_)),
          assertz(cache_connection(Conn)),
          retractall(last_answer(_)) ),
        repl_loop,
        ( cache_close(Conn),
          format("  [Cache closed]~n") )).
