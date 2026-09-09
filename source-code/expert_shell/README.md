# Expert System Shell

A reusable expert system shell with backward chaining and explanation facilities. Companion code for the Expert Systems chapter.

## Running Examples

```shell
cd source-code/expert_shell
swipl -s load.pl
```

Interactive (default KB, prompts the user):

```prolog
?- consult_expert(Conclusion).
?- explain(Conclusion).
```

Loading the sample wine KB and answering programmatically:

```prolog
?- load_kb('prolog/sample_kb.pl').
?- provide_answer(meal, red_meat).
?- provide_answer(bold_preference, yes).
?- consult_expert(C), explain(C).
```

User input is read with `read_line_to_string/2` (a trailing `.` is
stripped, numbers are converted automatically), so plain answers like
`yes` or `red_meat` work — no Prolog term syntax is required.  EOF
aborts the consultation gracefully.

## Running Tests

```shell
swipl -g "['tests/test_shell.pl'], run_tests, halt" -s load.pl
```


## Architecture

![Expert system shell with pluggable knowledge bases and backward chaining](FIG_expert_shell.jpg)

## Description

Provides a domain-independent expert system shell. The shell supports backward chaining inference with user interaction via `ask_question/1`, maintains a dynamic `known/2` database of user answers (reset via `reset_known/0`, seeded programmatically via `provide_answer/2`), and includes an explanation facility (`explain/1`) that traces the reasoning chain leading to a conclusion.

Knowledge bases are pluggable: `load_kb/1` loads a Prolog file defining `hypothesis/1` and `hypothesis_explanation/2` rules.  Conditions in hypotheses are evaluated via `shell:check/1`, which reuses cached `known/2` answers or prompts the user.  A ready-made example lives in `prolog/sample_kb.pl` (a small wine-selection KB); `make run` demos it non-interactively by answering with `provide_answer/2`.  The architecture separates the inference engine from domain knowledge, following the classic expert system design pattern.
