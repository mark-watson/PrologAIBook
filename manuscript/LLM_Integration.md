# LLM Integration

Large Language Models are transforming AI, and Prolog can serve as a powerful orchestration layer — combining LLM-generated text with symbolic reasoning, structured knowledge, and explainable inference.

## Calling LLM APIs from Prolog

SWI-Prolog's HTTP client libraries (covered in the Web Clients chapter) make it straightforward to call any REST API, including LLM endpoints. The workflow is:
1. Read the API key from an environment variable using `getenv/2`.
2. Build the JSON request payload as a Prolog term.
3. Send an HTTP POST request with `http_post/4`, which automatically serialises the payload and deserialises the JSON response into a SWI-Prolog dict.
4. Extract the generated text from the response dict using dot notation.

Because `http_post/4` is synchronous, the call blocks until the model returns its full response. For streaming responses (where tokens arrive incrementally), you would use `http_open/3` with a read loop — but for most Prolog applications, the simpler synchronous approach is sufficient.

{width: "80%"}
![Architecture diagram for the LLM Client example](FIG_llm_client.jpg)

The **llm_client** project provides clients for Google Gemini and Ollama. Here is the file **llm_client/prolog/gemini.pl**:

```prolog
%% gemini.pl - Google Gemini API client
:- module(gemini, [
    gemini_generate/2,
    gemini_generate/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).

%% gemini_generate(+Prompt, -Response)
%% Uses GOOGLE_API_KEY environment variable
gemini_generate(Prompt, Response) :-
    gemini_generate(Prompt, Response, []).

%% gemini_generate(+Prompt, -Response, +Options)
%% Options: model(Model), temperature(T), max_output_tokens(N)
gemini_generate(Prompt, Response, Options) :-
    require_env('GOOGLE_API_KEY', ApiKey),
    option_value(model, Options, Model, 'gemini-2.5-flash'),
    format(atom(URL),
           'https://generativelanguage.googleapis.com/v1beta/models/~w:generateContent',
           [Model]),
    option_value(temperature, Options, Temperature, none),
    option_value(max_output_tokens, Options, MaxTokens, none),
    Payload = _{
        contents: [_{parts: [_{text: Prompt}]}],
        generationConfig: Config
    },
    generation_config(Temperature, MaxTokens, ConfigPairs),
    (   ConfigPairs = []
    ->  Config = json([])
    ;   Config = json(ConfigPairs)
    ),
    catch(
        http_post(URL, json(Payload), Result,
                  [request_header('x-goog-api-key'=ApiKey),
                   json_object(dict)]),
        E,
        (   log_llm_error(gemini, E),
            fail
        )),
    extract_text_response(Result, Response).

%% generation_config(+Temperature, +MaxTokens, -ConfigPairs)
%% Build the generationConfig pairs for the payload body.
generation_config(none, none, []).
generation_config(T, none, [temperature=T]) :- T \= none.
generation_config(none, Max, [maxOutputTokens=Max]) :- Max \= none.
generation_config(T, Max, [temperature=T, maxOutputTokens=Max]) :-
    T \= none, Max \= none.

%% require_env(+Name, -Value)
%% Get an environment variable or throw a clear existence_error.
require_env(Name, Value) :-
    (   getenv(Name, Value)
    ->  true
    ;   existence_error(env, Name)
    ).

%% option_value(+Key, +Options, -Value, +Default)
%% Simple member-based option lookup (library(option) not required).
option_value(Key, Options, Value, Default) :-
    Opt =.. [Key, Value],
    (   member(Opt, Options)
    ->  true
    ;   Value = Default
    ).

%% extract_text_response(+Result, -Text)
%% Total: fails cleanly on error-shaped JSON (no candidates key).
extract_text_response(Result, Text) :-
    is_dict(Result),
    get_dict(candidates, Result, Candidates),
    Candidates = [First|_],
    is_dict(First),
    get_dict(content, First, Content),
    is_dict(Content),
    get_dict(parts, Content, Parts),
    Parts = [Part|_],
    is_dict(Part),
    get_dict(text, Part, Text).
```

The `gemini_generate/2` predicate reads the `GOOGLE_API_KEY` environment variable, constructs the Gemini API URL, builds the nested JSON payload, and posts it. The request sends the API key in the `x-goog-api-key` header, not in the URL. The options list accepts `model/1` (default `gemini-2.5-flash`), `temperature/1`, and `max_output_tokens/1`; `generation_config/3` turns those into the `generationConfig` body. `require_env/2` throws `existence_error(env, Name)` if the variable is unset. `extract_text_response/2` is total. It walks the response's `candidates[0].content.parts[0].text` path with `is_dict/1` and `get_dict/3` and fails cleanly on error-shaped JSON instead of throwing.

And a client for local Ollama models. Here is the file **llm_client/prolog/ollama.pl**:

```prolog
%% ollama.pl - Ollama local LLM API client
:- module(ollama, [
    ollama_generate/2,
    ollama_generate/3
]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).

%% ollama_generate(+Prompt, -Response)
%% Uses default model and localhost:11434
ollama_generate(Prompt, Response) :-
    ollama_generate(Prompt, Response, [model('qwen3:1.7b')]).

%% ollama_generate(+Prompt, -Response, +Options)
ollama_generate(Prompt, Response, Options) :-
    (member(model(Model), Options) -> true ; Model = 'qwen3:1.7b'),
    URL = 'http://localhost:11434/api/generate',
    Payload = json([
        model=Model,
        prompt=Prompt,
        stream= @(false)
    ]),
    catch(
        http_post(URL, json(Payload), Result, [json_object(dict)]),
        E,
        (   log_ollama_error(E),
            fail
        )),
    (   is_dict(Result),
        get_dict(response, Result, Response)
    ->  true
    ;   log_ollama_error(unexpected_response(Result)),
        fail
    ).
```

The Ollama client follows the same pattern but targets the local Ollama REST API on port 11434. The `stream= @(false)` option tells Ollama to return the complete response in a single JSON object rather than streaming tokens. The `http_post/4` call is wrapped in `catch/3`, and a connection-refused error prints a warning hinting "is the Ollama server running?" Response extraction is guarded by `is_dict/1` and `get_dict/3` so an unexpected reply fails with a warning instead of throwing. The model name defaults to `qwen3:1.7b` but can be overridden via the options list.

Both clients can be tested in the REPL:

```prolog
?- gemini_generate("What is Prolog?", Response).
Response = "Prolog is a logic programming language...".

?- ollama_generate("Explain backtracking", Response).
Response = "Backtracking is a systematic method...".
```

## Structured Output from LLMs

Raw LLM text is useful for human consumption, but for integration with Prolog's reasoning engine we need **structured data**. The key technique is to craft prompts that instruct the LLM to return its output as JSON with a specific schema. For example:

```
Extract all people and organizations from the following text.
Return your answer as JSON with this schema:
{"entities": [{"name": "...", "type": "person|org"}],
 "relations": [{"subject": "...", "predicate": "...", "object": "..."}]}
```

Once the LLM returns JSON, we parse it into a SWI-Prolog dict and assert the extracted entities and relations as dynamic Prolog facts. This bridges the gap between statistical language understanding (the LLM) and symbolic reasoning (Prolog).

{width: "80%"}
![Architecture diagram for the Structured Output example](FIG_structured_output.jpg)

The **structured_output** project converts JSON LLM output into assertable Prolog facts. Here is the file **structured_output/prolog/json_to_facts.pl**:

```prolog
%% json_to_facts.pl - Convert structured LLM JSON output into Prolog
%% facts
:- module(json_to_facts, [
    json_string_to_facts/1,     % +JsonString
    json_string_to_facts/2,     % +JsonString, -Counts
    clear_extracted/0,          %
    extracted_entity/2,
    extracted_relation/3
]).

:- use_module(library(json)).

:- dynamic extracted_entity/2.    % extracted_entity(Name, Type)
:- dynamic extracted_relation/3.  % extracted_relation(Subject,
                                  %            Predicate, Object)

%% clear_extracted/0
%% Remove every asserted entity/relation fact (test setup helper).
clear_extracted :-
    retractall(extracted_entity(_, _)),
    retractall(extracted_relation(_, _, _)).

%% json_string_to_facts(+JsonString)
%% Parses JSON with entities/relations arrays into Prolog facts
json_string_to_facts(JsonString) :-
    json_string_to_facts(JsonString, _Counts).

%% json_string_to_facts(+JsonString, -Counts)
%% As /1 but also returns a counts dict:
%%   _{entities: NE, entities_with_warnings: WE,
%%     relations: NR, relations_with_warnings: WR}.
%% Malformed items are skipped with a print_message/2 warning and
%% counted, never thrown.
json_string_to_facts(JsonString, Counts) :-
    atom_json_dict(JsonString, Dict, []),
    (   get_dict(entities, Dict, Entities)
    ->  foldl(assert_entity, Entities, 0-0, NE-WE)
    ;   NE = 0, WE = 0
    ),
    (   get_dict(relations, Dict, Relations)
    ->  foldl(assert_relation, Relations, 0-0, NR-WR)
    ;   NR = 0, WR = 0
    ),
    Counts = _{ entities: NE, entities_with_warnings: WE,
                relations: NR, relations_with_warnings: WR }.

assert_entity(E, N0-W0, N-W) :-
    (   get_dict(name, E, Name), get_dict(type, E, Type)
    ->  (   \+ extracted_entity(Name, Type)
        ->  assert(extracted_entity(Name, Type))
        ;   true
        ),
        N is N0 + 1, W = W0
    ;   print_message(warning,
            malformed_entity_skipped(E)),
        N = N0, W is W0 + 1
    ).

assert_relation(R, N0-W0, N-W) :-
    (   get_dict(subject, R, S),
        get_dict(predicate, R, P),
        get_dict(object, R, O)
    ->  (   \+ extracted_relation(S, P, O)
        ->  assert(extracted_relation(S, P, O))
        ;   true
        ),
        N is N0 + 1, W = W0
    ;   print_message(warning,
            malformed_relation_skipped(R)),
        N = N0, W is W0 + 1
    ).
```

The `json_string_to_facts/1` predicate parses the JSON string into a dict, then uses `get_dict/3` to safely extract the `entities` and `relations` arrays. `json_string_to_facts/2` returns a counts dict. Malformed items are skipped with a warning, never an exception. `clear_extracted/0` removes all asserted entities and relations. The `assert_entity/3` and `assert_relation/3` helpers are `foldl/4` accumulators that count asserted facts and warnings. The duplicate check (`\+ extracted_entity(Name, Type)`) prevents the same fact from being asserted twice if the LLM returns redundant extractions.

After calling `json_string_to_facts/1`, the extracted knowledge is immediately available for Prolog queries:

```prolog
?- json_string_to_facts('{"entities":[{"name":"Paris","type":"city"}]}').
true.

?- extracted_entity(Name, Type).
Name = "Paris",
Type = "city".
```

## Combining LLMs with Prolog Reasoning

The most powerful pattern in this book is the **hybrid AI pipeline**: use an LLM for tasks it excels at (natural language understanding, summarisation, information extraction) and use Prolog for tasks where it excels (structured reasoning, constraint satisfaction, explainable inference). Each system handles what it does best.

A typical hybrid pipeline has four stages:
1. **LLM Extraction** — The LLM processes unstructured text and returns structured JSON (entities, relations, classifications).
2. **Fact Assertion** — The JSON is parsed and asserted into Prolog's dynamic database as facts.
3. **Symbolic Reasoning** — Prolog rules fire over the asserted facts, producing conclusions, classifications, or recommendations.
4. **Explanation** — Prolog's proof-tree facilities (covered in the Reasoning chapter) explain *why* each conclusion was reached — something LLMs cannot reliably do.

{width: "80%"}
![Architecture diagram for the Hybrid Pipeline example](FIG_hybrid_pipeline.jpg)

The **hybrid_pipeline** project demonstrates this architecture using Python/spaCy for NER and Prolog for reasoning, connected via the Janus bridge. Here is the file **hybrid_pipeline/prolog/pipeline.pl**:

```prolog
%% pipeline.pl - Hybrid AI pipeline: Python preprocessing + Prolog
%% reasoning
:- module(pipeline, [
    run_pipeline/2
]).

:- use_module(library(janus)).

:- dynamic extracted/2.

% Resolve the companion python/ directory relative to this source file
% so the module works from any current working directory.
:- initialization(setup_python_path, main).

setup_python_path :-
    (   current_prolog_flag(windows, true)
    ->  Sep = '\\'
    ;   Sep = '/'
    ),
    once(source_file(pipeline:_, ThisFile)),
    file_directory_name(ThisFile, PrologDir),
    atomic_list_concat([PrologDir, '..', Sep, 'python'], PyDir),
    py_add_lib_dir(PyDir).

%% run_pipeline(+InputText, -Result)
%% 1. Use Python/spaCy for NER extraction
%% 2. Assert extracted entities as Prolog facts
%% 3. Apply Prolog reasoning rules
%% 4. Return structured conclusions
run_pipeline(InputText, Result) :-
    setup_call_cleanup(
        true,
        (   %% Step 1: Python NER
            py_call(nlp_bridge:extract_entities(InputText), Entities),
            %% Step 2: Assert as Prolog facts
            maplist(assert_entity, Entities),
            %% Step 3: Prolog reasoning
            findall(conclusion(E, Type), entity_conclusion(E, Type),
                Conclusions),
            Result = pipeline_result(Entities, Conclusions)
        ),
        %% Cleanup: always retract, even on failure or exception
        retractall(extracted(_,_))).

%% extract_entities/1 returns a list of dicts:  _{text: T, label: L}
assert_entity(Entity) :-
    Text = Entity.text,
    Type = Entity.label,
    assert(extracted(Text, Type)).

%% Only PERSON and GPE labels are mapped to conclusions; every other
%% spaCy entity label is deliberately dropped by these two clauses.
entity_conclusion(E, important_person) :-
    extracted(E, 'PERSON').
entity_conclusion(E, location) :-
    extracted(E, 'GPE').
```

The `run_pipeline/2` predicate orchestrates the full workflow. The `py_call/2` predicate (from `library(janus)`) calls Python's spaCy NER model to extract entities from the input text. Each entity comes back as a plain dict, and `assert_entity/1` reads its `text` and `label` fields in one pass before asserting it as an `extracted/2` fact. Prolog's `entity_conclusion/2` rules then classify them. The companion `python/` directory is resolved relative to this source file, so the module works from any current directory. The whole run is wrapped in `setup_call_cleanup/3` so `extracted/2` facts are retracted even on failure. The project ships a `pyproject.toml` pinning `spacy==3.8.11` and a `uv.lock`, so `uv` reproduces the exact Python environment.

This pattern generalises easily: replace spaCy with an LLM call (using our `gemini_generate/2` or `ollama_generate/2` clients), replace the simple classification rules with domain-specific expert system rules, and you have a production-grade hybrid AI system.

{width: "80%"}
![Architecture diagram for the Research Assistant example](FIG_research_assistant.jpg)

## Optional Practice Problems

1. **Fact Extraction Prompt**: Write a structured JSON prompt in the `structured_output` project that asks the LLM to output details about historical events. Parse this JSON into Prolog facts of the form `event(Name, Year, Location)`.
2. **System Instruction Support**: Extend the wrapper in `llm_client` to support system instructions, allowing you to configure the persona of the LLM before running queries.
