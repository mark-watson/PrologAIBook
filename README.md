# Practical AI Programming with Prolog

This book uses SWI-Prolog except for the last chapter that is specific to Scryer Prolog.

## SWI-Prolog (The Pragmatic Standard)
While this is a familiar environment for your daily work, looking at it from an author's perspective highlights why it is the de facto standard for "programming in the large."

- Capabilities: Massive library ecosystem, robust HTTP/web interfaces, multi-threading, and excellent Semantic Web/RDF support. It features tabling (crucial for dynamic programming and complex parsing) and robust foreign language interfaces (easily wrapping Python or C).
- Practical for building real, deployable AI agents, web scrapers, or integrating logic systems with modern machine learning pipelines, SWI-Prolog is the most practical primary target.

## Scryer Prolog (The Modern Wave)
- Capabilities: Written largely in Rust, aiming for strict ISO compliance and modern development ergonomics. Its standout feature is an incredibly memory-efficient representation of strings (using highly compressed character lists).
- Here we highlight the future of Prolog. Because of its memory efficiency, it makes Definite Clause Grammars (DCGs) highly practical for processing gigabytes of text. For applications like symbolic  NLP, Scryer is highly relevant.

