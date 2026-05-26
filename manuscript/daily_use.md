# Daily Use REPL: Gemini with Search and Cache

In a previous chapter we built a persistent cache engine using SQLite. Now we put it to practical use: an interactive command-line REPL that queries Google's Gemini API, optionally grounds answers with live Google Search results, and accumulates a persistent cache of useful responses that automatically enriches future prompts.

This chapter is a SWI-Prolog port of the Common Lisp `daily-use` tool. It demonstrates how Prolog's pattern matching and term manipulation make building an interactive command dispatcher particularly clean.

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

The architecture layers three components:

1. **Keyword extraction** — Splits user queries into meaningful terms by removing stop words, punctuation, and short tokens.
2. **Cache context builder** — Uses extracted keywords to retrieve relevant cached entries via the `cache_engine` library, then prepends them as context to the Gemini prompt.
3. **Gemini API client** — Sends prompts to the Google Generative Language API, with optional Google Search grounding via the `tools` parameter.

## Keyword Extraction

Before looking up the cache, we need to identify meaningful terms in the user's query. The `extract_keywords/2` predicate handles this pipeline:

{lang="prolog",linenos=off}
~~~~~~~~
:- module(daily_use, [
    main/0,
    extract_keywords/2,
    build_context_from_cache/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(readutil)).
~~~~~~~~

Stop words are declared as unit clauses — a natural Prolog idiom that makes lookups efficient via first-argument indexing (partial list, edited for brevity):

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

The extraction pipeline downcases, splits, strips punctuation, and filters:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

This approach mirrors the Common Lisp version's `extract-keywords` function, but uses Prolog's `maplist/3` and `include/3` higher-order predicates instead of `mapcar` and `remove-if`.

## Cache Context Builder

The context builder bridges keyword extraction and the cache engine:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

The key design decision is using `match_any(true)` — OR matching across keywords. This casts a wider net, retrieving any cached entry that mentions at least one of the query's keywords, rather than requiring all terms to match.

## Gemini API Integration

The module calls the Gemini API directly using SWI-Prolog's HTTP libraries, following the same pattern as the `llm_client` project:

{lang="prolog",linenos=off}
~~~~~~~~
call_gemini_api(Prompt, SearchP, Response) :-
    getenv('GOOGLE_API_KEY', ApiKey),
    model(Model),
    format(atom(URL),
           'https://generativelanguage.googleapis.com/v1beta/models/~w:generateContent?key=~w',
           [Model, ApiKey]),
    build_payload(Prompt, SearchP, Payload),
    http_post(URL, json(Payload), Result, [json_object(dict)]),
    extract_text_response(Result, Response).
~~~~~~~~

When search grounding is enabled (`!<query>`), the payload includes a `tools` array with `google_search`:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

Notice how Prolog's multi-clause predicates eliminate the need for `if/else` branching — the two `build_payload/3` clauses pattern-match on the `SearchP` argument.

## The REPL Loop

The REPL reads lines from standard input and dispatches on the input pattern using Prolog's clause-based dispatch:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

Each command is a separate `process_input/1` clause. This is cleaner than the Common Lisp version's `cond` block — each clause is self-contained and the cut (`!`) prevents fallthrough:

{lang="prolog",linenos=off}
~~~~~~~~
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
~~~~~~~~

## Running the REPL

Set your API key and run:

{linenos=off}
~~~~~~~~
$ export GOOGLE_API_KEY=your-key-here
$ cd source-code/daily_use
$ make run
~~~~~~~~

Or directly:

{linenos=off}
~~~~~~~~
$ swipl run.pl
~~~~~~~~

Here is an example session:

{linenos=off}
~~~~~~~~
  Gemini Daily-Use REPL  (type 'h' for help)

gemini> !what is the weather in Sedona AZ today?
  [Searching...]

Currently in Sedona, AZ it is partly cloudy and 78°F (26°C).

gemini> >
  [Cached. 1 items total]
gemini> what should I wear in Sedona today?
  [Thinking...]

Based on the current weather in Sedona (78°F and partly cloudy),
light layers would be ideal...

gemini> q
Goodbye.
  [Cache closed]
~~~~~~~~

Notice in the second query, the cached weather information was automatically included as context — the keyword "Sedona" matched the cached entry, giving Gemini the local conditions without needing another search.

## Wrap Up

This REPL demonstrates several Prolog strengths applied to a practical tool:

- **Clause-based dispatch** replaces procedural `switch`/`cond` statements with clean, self-documenting pattern matching.
- **Higher-order predicates** (`maplist`, `include`) provide the same functional pipeline as Common Lisp's `mapcar` and `remove-if`.
- **Dynamic predicates** (`last_answer/1`, `cache_connection/1`) provide mutable state where needed, while keeping the rest of the code purely declarative.
- **Module composition** — the daily_use module imports `cache_engine` for persistence and uses the standard HTTP libraries for API calls, demonstrating how Prolog modules compose cleanly.
