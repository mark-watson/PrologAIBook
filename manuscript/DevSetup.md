# Setting Up Your Prolog Development Environment

In this chapter we will install SWI-Prolog and configure a productive development environment. SWI-Prolog is the primary Prolog system used throughout this book.

## Installing SWI-Prolog

### macOS

On macOS, the most straightforward way to install SWI-Prolog is using the [Homebrew](https://brew.sh) package manager. Run the following command in your terminal:

```bash
brew install swi-prolog
```

This installs the stable version of SWI-Prolog, including the core execution engine, compiler, interactive top level (`swipl`), and development utilities.

#### Building from Source on macOS

If you prefer to build SWI-Prolog from source on macOS (for example, to enable optional modules or custom compile configurations), first install the required build dependencies via Homebrew:

```bash
brew install cmake ninja gmp openssl readline jpeg libarchive libyaml pcre2 pkg-config
```

Then, clone the official SWI-Prolog repository recursively to fetch all git submodules:

```bash
git clone --recursive https://github.com/SWI-Prolog/swipl-devel.git
cd swipl-devel
mkdir build
cd build
cmake -G Ninja ..
ninja
ninja install
```

### Linux

SWI-Prolog is available in the package repositories of most major Linux distributions.

#### Debian and Ubuntu

For Debian, Ubuntu, and derivative distributions, it is highly recommended to use the official SWI-Prolog Personal Package Archive (PPA) to ensure you install the latest stable version:

```bash
sudo apt-add-repository ppa:swi-prolog/stable
sudo apt update
sudo apt install swi-prolog
```

If you prefer the latest development release instead, you can add `ppa:swi-prolog/devel` instead.

#### Fedora, Red Hat, and CentOS

On Fedora or other systems using the `dnf` package manager, install SWI-Prolog with:

```bash
sudo dnf install swipl
```

### Windows

For Windows environments, precompiled binaries and installers are provided directly:

1. Visit the stable download page: [https://www.swi-prolog.org/download/stable](https://www.swi-prolog.org/download/stable).
2. Download the appropriate 64-bit installer for Windows.
3. Run the installer and proceed through the setup wizard.
4. **Important**: During the installation, make sure to check the option to add the SWI-Prolog bin directory to the system `PATH` environment variable. This allows you to launch the REPL by running `swipl` from command prompts or terminal windows (such as Command Prompt, PowerShell, or WSL).

---

## Editor Support

Writing Prolog is much more productive when using an editor configured with syntax highlighting, auto-indentation, and interactive execution helper tools.

### Visual Studio Code (VS Code)

VS Code is the most popular modern text editor for Prolog development:
- **Recommended Extension**: Search for and install the **VSC-Prolog** extension (by Arthur Wang).
- **Features**: Offers syntax highlighting, automatic linter feedback, tooltips with predicate signatures, and the ability to load your current file into an integrated SWI-Prolog REPL terminal.
- **Configuring the Executable**: If the extension displays an error indicating it cannot locate the Prolog engine, open your settings (`Ctrl+,` or `Cmd+,`) and set `prolog.executablePath` to the path of your `swipl` installation (e.g., `/usr/local/bin/swipl` on macOS/Linux, or `C:\Program Files\swipl\bin\swipl.exe` on Windows).

### Emacs

Emacs provides a classic, keyboard-driven environment with first-class support for SWI-Prolog:
- **Recommended Mode**: The built-in `prolog-mode` (which has specialized configurations optimized for SWI-Prolog).
- **Features**: Auto-indentation, syntax coloring, query execution, and the ability to run an interactive sub-process (`M-x run-prolog`) that compiles buffers dynamically.
- **Configuration**: Add the following setup code to your Emacs init file (`init.el`):
  ```elisp
  (setq prolog-system 'swi)
  ```

### The Built-in SWI-Prolog Editor (PceEmacs)

SWI-Prolog features a built-in GUI text editor based on its native graphical toolkit (XPCE). You can start the editor directly from the REPL shell:

```prolog
?- emacs.
```

To edit a specific file directly, run:

```prolog
?- edit(my_file).
```

This editor integrates tightly with the runtime engine, enabling semantic highlighting, immediate compilation error feedback, and quick navigation to predicate definitions.

---

## The SWI-Prolog Interactive Top Level

The interactive top level—often referred to as the REPL (Read-Eval-Print Loop)—is where you query and test your code.

### Starting and Exiting the REPL

To start the REPL, open your terminal and run the `swipl` command:

```bash
$ swipl
Welcome to SWI-Prolog (threaded, 64 bits, version 9.2.0)
...
?- 
```

To exit the REPL, type the `halt/0` predicate followed by a period:

```prolog
?- halt.
```

Alternatively, you can press `Ctrl-D` (on macOS/Linux) or `Ctrl-Z` followed by `Enter` (on Windows).

### Loading and Reloading Files

To load (or "consult") a local source file named `family.pl`:

```prolog
?- [family].
```

Note that the `.pl` extension is assumed automatically, and the query must end with a period.

If you modify `family.pl` in an external editor, reload the changes into the current REPL session with:

```prolog
?- make.
```

The `make/0` predicate automatically checks for modified files and recompiles them.

### Querying and Backtracking

Prolog queries are evaluated left-to-right. If variables are present, the REPL presents the first matching solution it finds.
- To search for more solutions, press the `;` (semicolon) key.
- To accept the current solution and return to the main prompt, press the `Enter` key (or `.`).

```prolog
?- parent(tom, Child).
Child = bob ;
Child = liz.
```

### Tracing and Debugging

SWI-Prolog includes a comprehensive debugging console based on the 4-port debugger model (Call, Exit, Redo, Fail):
- **Enable Tracing**: Type `trace.` and then run your query. The console will pause at every evaluation port.
- **Stepping**: During a trace, press the Spacebar to creep (step in) or `s` to skip (step over). Press `h` to display a menu of all trace options.
- **Disable Tracing**: Turn the debugger off using `notrace.`.
- **Spy Points**: If you only want to debug a specific predicate, set a spy point: `spy(my_predicate/2).`.
- **Graphical Debugger**: If you are in a GUI environment, you can open the visual debugger window:
  ```prolog
  ?- gtrace, my_query(X).
  ```

### Getting Help

Query the built-in manuals directly from the REPL:
- **Search for predicate documentation**:
  ```prolog
  ?- help(append/3).
  ```
- **Keyword search**:
  ```prolog
  ?- apropos(list).
  ```

---

## Installing Packs (Libraries)

SWI-Prolog includes a package manager for distributing community-contributed libraries, referred to as **packs**.

### Searching and Installing

To install a package, call `pack_install/1` with the pack name:

```prolog
?- pack_install(regex).
```

This retrieves the pack from the central repository, configures it, compiles any native foreign components (if needed), and installs it under your user configuration folder.

### Pack Management Commands

- **List installed packages**:
  ```prolog
  ?- pack_list('').
  ```
- **Upgrade a package to the latest version**:
  ```prolog
  ?- pack_upgrade(regex).
  ```
- **Uninstall a package**:
  ```prolog
  ?- pack_remove(regex).
  ```

---

## Cloning the Book's GitHub Repository

First, clone the GitHub repository that contains the example programs and the manuscript files for this book:

    git clone https://github.com/mark-watson/PrologAIBook.git

### Directory Structure Overview

The cloned repository contains two primary directories:

1. **`manuscript/`**: This folder contains the markdown chapters of the book.
2. **`source-code/`**: This folder contains all the companion Prolog projects, which are structured as modular codebases with tests. Here are some of the key source subdirectories:
   - **`tutorial_basics/`**: Entry-level programs covering lists, rules, and basic DCGs.
   - **`expert_shell/`**: A backward-chaining expert system engine that generates natural explanations.
   - **`scasp_compliance/`**: Code implementing regulatory compliance checks using the `s(CASP)` reasoning engine.
   - **`janus_ml_python_interop/`**: Interfacing Prolog directly with Python machine learning libraries using Janus.
   - **`prolog_wasm_web/`**: Code examples compiling Prolog logic to run client-side in the web browser via WebAssembly.
   - **`llm_logic_guardrails/`**: Structuring prompts, sending LLM queries, and verifying responses against formal logic guardrails.
   - **`agent_behavior_trees/`**: Implementing reactive logic-based behavior trees for agent action planning.

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

