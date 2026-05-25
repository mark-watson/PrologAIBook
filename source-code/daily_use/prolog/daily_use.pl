%% daily_use.pl — Interactive Gemini REPL with search grounding and
%% cache
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
    extract_keywords/2,
    build_context_from_cache/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(readutil)).

%% ---- Configuration ----

model('gemini-2.5-flash').
cache_db_path(Path) :-
    expand_file_name('~/.daily-use-cache', [Base]),
    atom_string(Base, Path).

%% ---- Mutable state (asserted/retracted) ----

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
%% Retrieves cached items relevant to Query via keyword overlap.
build_context_from_cache(Connection, Query, Context) :-
    extract_keywords(Query, Keywords),
    ( Keywords = [] ->
        Context = ""
    ;
        cache_engine:cache_lookup(Connection, Keywords, Items,
                                   [limit(10), match_any(true)]),
        ( Items = [] ->
            Context = ""
        ;
            format_context_items(Items, Formatted),
            format(atom(Context),





                                       "Use the following context from previous conversations when answering:\n\n~w\n---\n\n",
                   [Formatted])
        )
    ).

format_context_items([], '').
format_context_items([Item|Rest], Formatted) :-
    format_context_items(Rest, RestFmt),
    format(atom(Formatted), "- ~w\n~w", [Item, RestFmt]).

%% ---- Gemini API calls ----

%% ask_gemini(+Connection, +Prompt, +SearchP, -Answer)
ask_gemini(Connection, Prompt, SearchP, Answer) :-
    build_context_from_cache(Connection, Prompt, Context),
    atom_concat(Context, Prompt, FullPrompt),
    catch(
        call_gemini_api(FullPrompt, SearchP, Answer),
        Error,
        ( term_to_atom(Error, ErrAtom),
          atom_concat('[Error calling Gemini API: ', ErrAtom, Tmp),
          atom_concat(Tmp, ']', Answer) )
    ).

%% call_gemini_api(+Prompt, +SearchP, -Response)
call_gemini_api(Prompt, SearchP, Response) :-
    getenv('GOOGLE_API_KEY', ApiKey),
    model(Model),
    format(atom(URL),





                               'https://generativelanguage.googleapis.com/v1beta/models/~w:generateContent?key=~w',
           [Model, ApiKey]),
    build_payload(Prompt, SearchP, Payload),
    http_post(URL, json(Payload), Result, [json_object(dict)]),
    extract_text_response(Result, Response).

build_payload(Prompt, false, Payload) :-
    Payload = json([
        contents=[json([
            parts=[json([text=Prompt])]
        ])]
    ]).
build_payload(Prompt, true, Payload) :-
    Payload = json([
        contents=[json([
            parts=[json([text=Prompt])]
        ])],
        tools=[json([
            google_search=json([])
        ])]
    ]).

extract_text_response(Result, Text) :-
    Candidates = Result.candidates,
    [First|_] = Candidates,
    Content = First.content,
    Parts = Content.parts,
    [Part|_] = Parts,
    Text = Part.text.

%% ---- Help text ----

print_help :-
    cache_connection(Conn),
    cache_engine:cache_count(Conn, N),
    cache_db_path(DbPath),
    model(Model),
    format("~n  Gemini Daily-Use REPL~n"),
    format("  ─────────────────────────────────────────~n"),
    format("  <text>         Ask Gemini a question~n"),
    format("  !<text>        Ask with Google Search grounding~n"),
    format("  >              Add last answer to cache~n"),
    format("  !              Clear cache entries older than 1 week~n"),
    format("  h / help       Show this help~n"),
    format("  q / quit       Exit~n"),
    format("  Ctrl-D         Exit~n"),
    format("  ─────────────────────────────────────────~n"),
    format("  Model: ~w~n", [Model]),
    format("  Cache: ~w (~w items)~n~n", [DbPath, N]).

%% ---- Display answer ----

display_answer(Text) :-
    ( nonvar(Text), Text \= '' ->
        format("~n~w~n~n", [Text]),
        retractall(last_answer(_)),
        assert(last_answer(Text))
    ;





                            format("~n  [No response from Gemini — check model name or API key]~n~n")
    ).

%% ---- REPL ----

repl_loop :-
    format("~n  Gemini Daily-Use REPL  (type 'h' for help)~n~n"),
    repl_iteration.

repl_iteration :-
    format("gemini> "),
    flush_output,
    catch(
        read_line_to_string(current_input, RawInput),
        _,
        ( format("~nGoodbye.~n"), ! )
    ),
    ( RawInput == end_of_file ->
        format("~nGoodbye.~n")
    ;
        normalize_space(atom(Trimmed), RawInput),
        process_input(Trimmed),
        repl_iteration
    ).

%% process_input(+Input)
%% Dispatches the trimmed user input to the appropriate handler.

% Empty line — skip
process_input('') :- !.

% Quit commands
process_input(q)    :- !, format("Goodbye.~n"), halt(0).
process_input(quit) :- !, format("Goodbye.~n"), halt(0).
process_input(exit) :- !, format("Goodbye.~n"), halt(0).

% Help
process_input(h)    :- !, print_help.
process_input(help) :- !, print_help.

% ">" — cache last answer
process_input('>') :- !,
    ( last_answer(Ans) ->
        cache_connection(Conn),
        cache_engine:cache_add(Conn, Ans),
        cache_engine:cache_count(Conn, N),
        format("  [Cached. ~w items total]~n", [N])
    ;
        format("  [No answer to cache yet]~n")
    ).

% "!" alone — clear old cache entries
process_input('!') :- !,
    cache_connection(Conn),
    cache_engine:cache_count(Conn, Before),
    cache_engine:cache_clear_older_one_week(Conn),
    cache_engine:cache_count(Conn, After),
    Cleared is Before - After,
    format("  [Cleared ~w old entries. ~w items remain]~n", [Cleared,
        After]).

% "!<query>" — search-grounded question
process_input(Input) :-
    atom_concat('!', Rest, Input),
    Rest \= '',
    !,
    normalize_space(atom(Query), Rest),
    ( Query = '' ->
        process_input('!')
    ;
        format("  [Searching...]~n"),
        flush_output,
        cache_connection(Conn),
        ask_gemini(Conn, Query, true, Answer),
        display_answer(Answer)
    ).

% Plain question
process_input(Input) :-
    format("  [Thinking...]~n"),
    flush_output,
    cache_connection(Conn),
    ask_gemini(Conn, Input, false, Answer),
    display_answer(Answer).

%% ---- Entry point ----

%% main/0
%% Initialize cache and start the REPL.
main :-
    ( getenv('GOOGLE_API_KEY', _) ->
        true
    ;





                            format("Error: GOOGLE_API_KEY environment variable is not set.~n"),





                            format("Export it before running:  export GOOGLE_API_KEY=your-key-here~n"),
        halt(1)
    ),
    cache_db_path(DbPath),
    cache_engine:cache_open(DbPath, Conn),
    retractall(cache_connection(_)),
    assert(cache_connection(Conn)),
    retractall(last_answer(_)),
    catch(
        repl_loop,
        _,
        true
    ),
    cache_engine:cache_close(Conn),
    format("  [Cache closed]~n").
