# Setting Up Your Prolog Development Environment

In this chapter we install SWI-Prolog and set up a development environment. The book uses SWI-Prolog for all chapters except the one on Scryer Prolog.

## Installing SWI-Prolog

### macOS

On macOS, the easiest way to install SWI-Prolog is with the [Homebrew](https://brew.sh) package manager:

```bash
brew install swi-prolog
```

This installs the stable version of SWI-Prolog, including the compiler, the interactive top level (`swipl`), and the standard libraries.

Two later chapters need extra setup. The Janus Python bridge in the Homebrew build may fail to load with an error like `Library not loaded: @rpath/Python3.framework/Versions/3.9/Python3`. The chapter **The Janus Python Bridge** shows how to fix this. The **Cache Engine** and **Daily Use REPL** chapters need the `prosqlite` pack, which we install later in this chapter.

#### Building from Source on macOS

To build SWI-Prolog from source on macOS (for example, to enable optional modules), first install the build dependencies with Homebrew:

```bash
brew install cmake ninja gmp openssl readline jpeg libarchive libyaml pcre2 pkg-config
```

Then clone the SWI-Prolog repository with its git submodules and build it:

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

Most Linux distributions include SWI-Prolog in their package repositories.

#### Debian and Ubuntu

On Debian, Ubuntu, and related distributions, use the SWI-Prolog Personal Package Archive (PPA) to get the latest stable version:

```bash
sudo apt-add-repository ppa:swi-prolog/stable
sudo apt update
sudo apt install swi-prolog
```

For the latest development release, add `ppa:swi-prolog/devel` instead.

#### Fedora, Red Hat, and CentOS

On Fedora or other systems that use `dnf`:

```bash
sudo dnf install swipl
```

### Windows

For Windows, SWI-Prolog provides installers:

1. Visit the stable download page: [https://www.swi-prolog.org/download/stable](https://www.swi-prolog.org/download/stable).
2. Download the appropriate 64-bit installer for Windows.
3. Run the installer.
4. **Important**: During setup, check the option to add the SWI-Prolog `bin` directory to the `PATH` environment variable. You can then start the REPL by running `swipl` from Command Prompt or PowerShell.

---

## Editor Support

An editor with syntax highlighting, auto-indentation, and a built-in REPL makes Prolog work faster.

### Visual Studio Code (VS Code)

- **Extension**: Install the **VSC-Prolog** extension (by Arthur Wang).
- **Features**: Syntax highlighting, linter feedback, tooltips with predicate signatures, and a command to load the current file into a SWI-Prolog REPL terminal.
- **Setting the executable**: If the extension cannot find Prolog, open settings (`Ctrl+,` or `Cmd+,`) and set `prolog.executablePath` to your `swipl` path (for example `/opt/homebrew/bin/swipl` on Apple Silicon Macs, `/usr/bin/swipl` on Linux, or `C:\Program Files\swipl\bin\swipl.exe` on Windows).

### Emacs

- **Mode**: The built-in `prolog-mode`, which has settings for SWI-Prolog.
- **Features**: Auto-indentation, syntax coloring, and an interactive Prolog process (`M-x run-prolog`) that can load buffers.
- **Configuration**: Add this line to your Emacs init file (`init.el`):
  ```elisp
  (setq prolog-system 'swipl)
  ```

---

## The SWI-Prolog Interactive Top Level

The interactive top level, often called the REPL (Read-Eval-Print Loop), is where you query and test your code.

### Starting and Exiting the REPL

To start the REPL, open your terminal and run the `swipl` command:

```bash
$ swipl
Welcome to SWI-Prolog (threaded, 64 bits, version 10.0.2)
...
?- 
```

To exit the REPL, type `halt` followed by a period:

```prolog
?- halt.
```

You can also press `Ctrl-D` (macOS and Linux) or `Ctrl-Z` then `Enter` (Windows).

### Loading and Reloading Files

To load (or "consult") a local source file named `family.pl`:

```prolog
?- [family].
```

Prolog adds the `.pl` extension, and the query must end with a period.

If you edit `family.pl` in an editor, reload it with:

```prolog
?- make.
```

The `make/0` predicate finds changed files and recompiles them.

### Querying and Backtracking

Prolog runs the goals in a query from left to right. If the query has variables, the REPL shows the first solution it finds.
- To see more solutions, press `;` (semicolon).
- To accept the current solution and return to the prompt, press `Enter` (or `.`).

```prolog
?- parent(tom, Child).
Child = bob ;
Child = liz.
```

### Tracing and Debugging

SWI-Prolog's debugger uses the four-port model (Call, Exit, Redo, Fail):
- **Start tracing**: Type `trace.` and then run your query. The debugger stops at each port.
- **Stepping**: Press the space bar to creep (step in) or `s` to skip (step over). Press `h` to list all options.
- **Stop tracing**: Type `notrace.`.
- **Spy points**: To debug one predicate, set a spy point: `spy(my_predicate/2).`.
- **Graphical debugger**: On a desktop, open the visual debugger with:
  ```prolog
  ?- gtrace, my_query(X).
  ```

### Getting Help

You can read the manual from the REPL:
- **Show a predicate's documentation**:
  ```prolog
  ?- help(append/3).
  ```
- **Keyword search**:
  ```prolog
  ?- apropos(list).
  ```

---

## Installing Packs (Libraries)

SWI-Prolog has a package manager for community libraries, called **packs**.

### Searching and Installing

To install a pack, call `pack_install/1` with its name:

```prolog
?- pack_install(regex).
```

This downloads the pack, compiles any C code it contains, and installs it in your user configuration folder.

The **Cache Engine** and **Daily Use REPL** chapters need the `prosqlite` pack for SQLite access. Install it now:

```prolog
?- pack_install(prosqlite).
```

### Pack Management Commands

- **List installed packs**:
  ```prolog
  ?- pack_list_installed.
  ```
- **Upgrade a pack to the latest version**:
  ```prolog
  ?- pack_upgrade(regex).
  ```
- **Remove a pack**:
  ```prolog
  ?- pack_remove(regex).
  ```

---

## Cloning the Book's GitHub Repository

Clone the repository that holds this book's example programs and manuscript files:

    git clone https://github.com/mark-watson/PrologAIBook.git

### Directory Structure Overview

The repository has two main directories:

1. **`manuscript/`**: The book's chapters in Markdown.
2. **`source-code/`**: The example projects, most with modules and tests. The file **SOURCE_CODE_MAP.md** at the top level maps each chapter to its projects. Some examples:
   - **`tutorial_basics/`**: Entry-level programs covering lists, rules, and basic DCGs.
   - **`expert_shell/`**: A backward-chaining expert system engine that generates natural explanations.
   - **`scasp_compliance/`**: Code implementing regulatory compliance checks using the `s(CASP)` reasoning engine.
   - **`janus_ml_python_interop/`**: Interfacing Prolog directly with Python machine learning libraries using Janus.
   - **`prolog_wasm_web/`**: Prolog rules that run in the web browser through WebAssembly.
   - **`llm_logic_guardrails/`**: Checking LLM output against Prolog rules.
   - **`agent_behavior_trees/`**: Behavior trees for agent action selection.

Most projects have a **Makefile** with two targets: `make run` runs the examples and `make test` runs the unit tests.

## Project Organization and Best Practices

A good SWI-Prolog project follows the pack layout (even if you never publish it) and uses the module and unit test systems. This section shows the layout the book's projects use.

### Standard Project Layout

The usual layout copies the pack layout, which keeps metadata, source code, and tests apart.

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

- **prolog/**: Your application code. Make every file here a module.
- **load.pl**: Loads your application into the REPL. It usually holds directives like `:- use_module(prolog/core).`
- **tests/**: Unit tests, kept apart from the application code.

### Defining Dependencies with pack.pl

The **pack.pl** file at the project root holds Prolog terms that give the project's metadata and dependencies.

Example **pack.pl**:

```prolog
name(my_project).
version('0.1.0').
title('A concise Prolog application').
author('Your Name', 'email@example.com').

% Dependencies
requires(prolog >= '9.2.0').           % Minimum SWI-Prolog version
requires(prolog:library(clpfd)).      % Library shipped with SWI-Prolog
requires(regex).                       % External pack
```

A plain name such as `regex` names an external pack. The `prolog:library(Lib)` form checks for a library that ships with SWI-Prolog, so do not list built-in libraries by bare name. If you publish your project as a pack, `pack_install/1` installs the packs it requires. For a project you only run locally, install each pack yourself:

```prolog
?- pack_install(regex).
```

### Organizing Source Files with Modules

Modules prevent predicate name clashes as a code base grows. At the top of each file in **prolog/**, declare the module and list the predicates it exports. SWI-Prolog reports an error if a module exports a predicate it does not define.

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

evaluate_state(State) :-
    State #>= 0.

clean_input(X, X).
```

The module imports `utils`, so the project also needs **prolog/utils.pl**. A module with no exports is enough to start:

```prolog
:- module(utils, []).
```

### Unit Testing with PLUnit

SWI-Prolog ships with the **plunit** test framework. You can put tests inside your source modules, but a separate **tests/** directory is cleaner for larger projects.

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
    _X is _Y + 1.

:- end_tests(core_logic).
```

**Running the Tests:**

To run the tests from the REPL, load the test file and call the test runner:

```prolog
?- [load].
?- ['tests/test_core.pl'].
?- run_tests.
```

To run them from the command line:

```bash
swipl -g "['tests/test_core.pl'], run_tests, halt" -s load.pl
```

The book's Makefiles use this command for their `test` targets. You may see `load_test_files/1` in other projects. It loads `.plt` files that sit next to each source file, so it does not find tests in a separate **tests/** directory.

