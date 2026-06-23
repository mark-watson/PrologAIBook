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
gemini_generate(Prompt, Response, _Options) :-
    getenv('GOOGLE_API_KEY', ApiKey),
    format(atom(URL),
           'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=~w',
           [ApiKey]),
    Payload = json([
        contents=[json([
            parts=[json([text=Prompt])]
        ])]
    ]),
    http_post(URL, json(Payload), Result, [json_object(dict)]),
    extract_text_response(Result, Response).

extract_text_response(Result, Text) :-
    Candidates = Result.candidates,
    [First|_] = Candidates,
    Content = First.content,
    Parts = Content.parts,
    [Part|_] = Parts,
    Text = Part.text.
```

The `gemini_generate/2` predicate reads the `GOOGLE_API_KEY` environment variable, constructs the Gemini API URL, builds the nested JSON payload, and posts it. The `extract_text_response/2` helper navigates the response dict's `candidates[0].content.parts[0].text` path using SWI-Prolog's dot notation for dicts.

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
    http_post(URL, json(Payload), Result, [json_object(dict)]),
    Response = Result.response.
```

The Ollama client follows the same pattern but targets the local Ollama REST API on port 11434. The `stream= @(false)` option tells Ollama to return the complete response in a single JSON object rather than streaming tokens. The model name defaults to `qwen3:1.7b` but can be overridden via the options list.

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
    json_string_to_facts/1,
    extracted_entity/2,
    extracted_relation/3
]).

:- use_module(library(json)).

:- dynamic extracted_entity/2.    % extracted_entity(Name, Type)
:- dynamic extracted_relation/3.  % extracted_relation(Subject,
                                  %            Predicate, Object)

%% json_string_to_facts(+JsonString)
%% Parses JSON with entities/relations arrays into Prolog facts
json_string_to_facts(JsonString) :-
    atom_json_dict(JsonString, Dict, []),
    (   get_dict(entities, Dict, Entities)
    ->  maplist(assert_entity, Entities)
    ;   true
    ),
    (   get_dict(relations, Dict, Relations)
    ->  maplist(assert_relation, Relations)
    ;   true
    ).

assert_entity(E) :-
    Name = E.name,
    Type = E.type,
    (   \+ extracted_entity(Name, Type)
    ->  assert(extracted_entity(Name, Type))
    ;   true
    ).

assert_relation(R) :-
    S = R.subject,
    P = R.predicate,
    O = R.object,
    (   \+ extracted_relation(S, P, O)
    ->  assert(extracted_relation(S, P, O))
    ;   true
    ).
```

The `json_string_to_facts/1` predicate parses the JSON string into a dict, then uses `get_dict/3` to safely extract the `entities` and `relations` arrays (defaulting to no-op if either is missing). The `maplist/2` calls iterate over each array element, asserting facts into the dynamic database. The duplicate check (`\+ extracted_entity(Name, Type)`) prevents the same fact from being asserted twice if the LLM returns redundant extractions.

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

%% run_pipeline(+InputText, -Result)
%% 1. Use Python/spaCy for NER extraction
%% 2. Assert extracted entities as Prolog facts
%% 3. Apply Prolog reasoning rules
%% 4. Return structured conclusions
run_pipeline(InputText, Result) :-
    %% Step 1: Python NER
    py_call(nlp_bridge:extract_entities(InputText), Entities),
    %% Step 2: Assert as Prolog facts
    maplist(assert_entity, Entities),
    %% Step 3: Prolog reasoning
    findall(conclusion(E, Type), entity_conclusion(E, Type),
        Conclusions),
    Result = pipeline_result(Entities, Conclusions),
    %% Cleanup
    retractall(extracted(_,_)).

:- dynamic extracted/2.

assert_entity(Entity) :-
    py_call(Entity:label_, Type),
    py_call(Entity:text, Text),
    assert(extracted(Text, Type)).

entity_conclusion(E, important_person) :-
    extracted(E, 'PERSON').
entity_conclusion(E, location) :-
    extracted(E, 'GPE').
```

The `run_pipeline/2` predicate orchestrates the full workflow. The `py_call/2` predicate (from `library(janus)`) calls Python's spaCy NER model to extract entities from the input text. Each entity is then asserted as an `extracted/2` fact, and Prolog's `entity_conclusion/2` rules classify them. The `retractall/1` at the end cleans up the dynamic facts so the next pipeline run starts fresh.

This pattern generalises easily: replace spaCy with an LLM call (using our `gemini_generate/2` or `ollama_generate/2` clients), replace the simple classification rules with domain-specific expert system rules, and you have a production-grade hybrid AI system.

{width: "80%"}
![Architecture diagram for the Research Assistant example](FIG_research_assistant.jpg)

## Optional Practice Problems

1. **Fact Extraction Prompt**: Write a structured JSON prompt in the `structured_output` project that asks the LLM to output details about historical events. Parse this JSON into Prolog facts of the form `event(Name, Year, Location)`.
2. **System Instruction Support**: Extend the wrapper in `llm_client` to support system instructions, allowing you to configure the persona of the LLM before running queries.
