# Daily Use REPL: Gemini with Search and Cache

The previous chapter built a cache engine on SQLite. Now we use it in an interactive command-line REPL that asks Google's Gemini questions, optionally lets it search the web, and keeps a cache of useful answers that it adds to later prompts as context.

This is a SWI-Prolog port of my Common Lisp `daily-use` tool, which I use every day. Prolog's clause-by-clause pattern matching makes the command dispatcher short.

## Design Overview

The REPL supports six commands:

| Input | Action |
|-------|--------|
| `<text>` | Ask Gemini a question |
| `!<text>` | Ask with Google Search grounding |
| `>` | Cache the last answer |
| `!` | Clear cache entries older than 1 week |
| `h` / `help` | Show help |
| `q` / `quit` | Exit |

It has three parts:

1. **Keyword extraction**: Finds the meaningful words in a question by removing stop words, punctuation, and short words.
2. **Cache context builder**: Looks up cached answers that contain those words and puts them before the question in the prompt.
3. **Gemini client**: Sends the prompt to Gemini, with Google Search turned on for `!` questions.

## Keyword Extraction

Here is the module header of **daily_use/prolog/daily_use.pl**. It loads the cache engine from the previous chapter and the Gemini client from the LLM Integration chapter:

```prolog
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
```

Before looking up the cache, we need the meaningful terms in the user's question. Stop words are facts, so first-argument indexing makes each lookup fast (this is part of the list):

```prolog
stop_word(a).
stop_word(an).
stop_word(the).
stop_word(am). stop_word(it). stop_word(its).
stop_word(in).
stop_word(not).
stop_word(no).
stop_word(nor). stop_word(so). stop_word(yet).
stop_word(this). stop_word(that). stop_word(these). stop_word(those).
stop_word(what). stop_word(which). stop_word(who). stop_word(whom).
```

`extract_keywords/2` lowercases the text, splits it into words, strips punctuation, and drops stop words and words of two letters or fewer:

```prolog
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
```

This mirrors the Common Lisp version's `extract-keywords` function, with `maplist/3` and `include/3` in place of `mapcar` and `remove-if`.

## Cache Context Builder

The context builder connects keyword extraction to the cache engine:

```prolog
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
```

`match_any(true)` asks for entries that contain *any* of the keywords, not all of them, which finds more context. The cache engine returns the newest entries first.

## Asking Gemini

The calls to Gemini go through `gemini_generate/3` from the LLM Integration chapter. Its `search(true)` option adds Google Search to the request (`"tools": [{"google_search": {}}]`), so Gemini can look up current facts, and it joins the text of every part of the reply, since a search-grounded reply can come in several parts:

```prolog
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
```

`ask/3` opens and closes the cache itself, so you can ask one question without the REPL: `make ask Q="What is unification?"`. Inside the REPL, `ask_gemini/4` uses the connection the REPL already opened. An API error becomes an answer string rather than an exception, so one failed request does not end the session.

## The REPL Loop

The REPL reads a line, hands it to `process_input/2`, and loops:

```prolog
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
```

Each command is one clause of `process_input/2`, matched by its first argument, and the cut stops later clauses from also matching. Compare this with a long `cond` or `switch` in other languages: each clause stands alone. The second argument tells the loop whether to go on. A quit command returns `stop`, so the loop ends normally instead of calling `halt/1`, and `main/0` can close the cache:

```prolog
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
```

## Running the REPL

Set your API key and run the REPL:

{linenos=off}
~~~~~~~~
$ export GOOGLE_API_KEY=your-key-here
$ cd source-code/daily_use
$ make run
~~~~~~~~

Or run `swipl run.pl` directly. The cache file is **~/.daily-use-cache.db**; set the `DAILY_USE_CACHE` environment variable to use another file.

Here is a real session. The first question uses search, `>` caches its answer, and the second question has no search:

{linenos=off}
~~~~~~~~
  Gemini Daily-Use REPL  (type 'h' for help)

gemini> !What is the latest stable release of SWI-Prolog? Answer in one sentence.
  [Searching...]

The latest stable release of SWI-Prolog is version 11.0.

gemini> >
  [Cached. 1 items total]
gemini> What is new in that SWI-Prolog release? Answer in two sentences.
  [Thinking...]

SWI-Prolog 11.0 introduces a significant rewrite of its tabling engine,
delivering enhanced performance and robustness for declarative
memoization. Additionally, it brings substantial improvements to the type
system with new predicates like `must_be/2`, alongside general performance
optimizations and library updates.

gemini> q
Goodbye.
  [Cache closed]
~~~~~~~~

The second question never says "11.0", yet the answer knows it: the keywords `swi-prolog`, `release`, and `answer` all occur in the cached answer (SQLite's `LIKE` ignores case), so it went into the prompt as context. That is the cache doing its job.

The session also shows the cache's limit. The second answer had no search, so its details come from the model's memory, and at least one is wrong: `must_be/2` is not new; it has been in `library(error)` for many years. Context from the cache makes the model sound well informed even when it is guessing. Use `!` when the details matter, and do not cache answers you have not checked.

## Wrap Up

This REPL demonstrates several Prolog strengths applied to a practical tool:

- **Clause-based dispatch** replaces a `switch` or `cond` with one clause per command.
- **Higher-order predicates** (`maplist`, `include`) give the same pipeline style as Common Lisp's `mapcar` and `remove-if`.
- **Dynamic predicates** (`last_answer/1`, `cache_connection/1`) hold the little state the REPL needs.
- **Module reuse**: the module uses the cache engine and the Gemini client from earlier chapters without changing them.
- **Cleanup**: `setup_call_cleanup/3` closes the cache however the REPL ends.

## Optional Practice Problems

1. **Command-Line Options**: Use `argv_options/3` in `run.pl` to accept `--model=NAME` and `--cache=FILE`, and report unknown options.
2. **Show the Context**: Add a command `?` that prints the cached entries that would go into the prompt for the last question, so you can see what the model was given.
3. **Cache Only Grounded Answers**: Change the `>` command to refuse answers that were not produced with search, and print a message explaining why.
