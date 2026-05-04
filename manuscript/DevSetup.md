# Setting Up Your Prolog Development Environment

In this chapter we will install SWI-Prolog and configure a productive development environment. SWI-Prolog is the primary Prolog system used throughout this book.

## Installing SWI-Prolog

### macOS

TBD: Homebrew installation and building from source.

### Linux

TBD: Package manager installation (apt, dnf) and PPA options.

### Windows

TBD: Installer download from swi-prolog.org.

## Editor Support

TBD: Recommended editors and plugins — Emacs with prolog-mode, VSCode with VSC-Prolog, and the built-in SWI-Prolog editor.

## The SWI-Prolog Interactive Top Level

TBD: Using the REPL (top level), loading files, tracing execution, and getting help.

## Installing Packs (Libraries)

TBD: Using `pack_install/1` to install third-party libraries. Overview of the SWI-Prolog pack ecosystem.

## Cloning the Book's GitHub Repository

First, clone the GitHub repository that contains the example programs and the manuscript files for this book:

    git clone https://github.com/mark-watson/PrologAIBook.git

TBD: Directory structure overview.

## Project Organization and Best Practices

Setting up a robust SWI-Prolog project involves adopting package management conventions (even if you aren't publishing it publicly) and utilizing the built-in module and testing systems. Here is the standard approach to structuring, managing dependencies, and testing in SWI-Prolog.

### Standard Project Layout

The most idiomatic way to structure a modern SWI-Prolog project mimics its package manager (pack) layout. This cleanly separates metadata, source code, and tests.

```
my_project/
├── pack.pl          # Project metadata and dependencies
├── load.pl          # Main entry point / bootstrapper
├── prolog/          # Application source files
│   ├── core.pl      
│   └── utils.pl
└── tests/           # Unit tests (plunit)
    ├── test_core.pl
    └── test_utils.pl
```

- **prolog/**: Contains your actual logic. Every file here should be a module.
- **load.pl**: A convenience script used to load your application into the REPL. It typically contains directives like `:- use_module(prolog/core).`
- **tests/**: Kept separate from source code to avoid polluting the production footprint.

### Defining Dependencies with pack.pl

SWI-Prolog manages dependencies via the **pack.pl** file located at the project root. This file contains Prolog terms declaring metadata and required libraries (both built-in and external packs).

Example **pack.pl**:

```prolog
name(my_project).
version('0.1.0').
title('A concise Prolog application').
author('Your Name', 'email@example.com').

% Dependencies
requires(http).           % Built-in SWI-Prolog library
requires(clpfd).          % Constraint Logic Programming
requires(regex).          % External pack (needs installation)
```

To install external dependencies defined in this file, you would run the following from the SWI-Prolog REPL in your project root:

```prolog
?- pack_install('.').
```

### Organizing Source Files with Modules

To prevent predicate name collisions across a growing codebase, encapsulate your source files using SWI-Prolog's module system. At the top of every file in your **prolog/** directory, declare the module and explicitly export the predicates intended for public use.

**prolog/core.pl**:

```prolog
:- module(core, [
    process_data/2,   % Exported predicate
    evaluate_state/1  % Exported predicate
]).

:- use_module(utils). % Import another local module
:- use_module(library(clpfd)). % Import a dependency

% Implementation
process_data(Input, Output) :-
    clean_input(Input, Cleaned), % Private predicate
    Output = Cleaned.

clean_input(X, X).
```

### Unit Testing with PLUnit

SWI-Prolog includes the **plunit** testing framework natively. While you can embed tests directly inside your source modules, placing them in a dedicated **tests/** directory is cleaner for larger projects.

**tests/test_core.pl**:

```prolog
:- module(test_core, []).
:- use_module(library(plunit)).
:- use_module('../prolog/core').

:- begin_tests(core_logic).

test(process_data_valid) :-
    process_data(raw_data, Output),
    assertion(Output == raw_data).

test(fail_case, [fail]) :-
    process_data(invalid, valid).

test(throws_error, [error(instantiation_error)]) :-
    X is Y + 1.

:- end_tests(core_logic).
```

**Running the Tests:**

You can run your test suite from the REPL by loading the test files and executing the test runner:

```prolog
?- load_test_files([]).
?- run_tests.
```

Alternatively, to test from the command line without entering the interactive REPL:

```
swipl -g "load_test_files([]), run_tests, halt" -s load.pl
```

