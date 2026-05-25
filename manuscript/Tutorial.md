# Prolog Tutorial

This chapter provides a hands-on introduction to Prolog for readers who are new to logic programming. We cover the essential concepts needed to understand the AI applications in later chapters.

{width: "80%"}
![Architecture diagram for the Tutorial Basics example](FIG_tutorial_basics.jpg)

## Facts, Rules, and Queries

Prolog, which stands for *Programming in Logic*, is based on a subset of first-order predicate calculus. Unlike imperative languages where you specify *how* to compute something, Prolog is declarative: you describe the *what*—the facts and rules governing a problem domain—and let the execution engine deduce the answers to your queries.

The fundamental building blocks of a Prolog program are **terms**, which make up the data model:
- **Atoms**: Constant values representing specific objects or relations. They are written starting with a lowercase letter (e.g., `tom`, `bob`, `parent`) or enclosed in single quotes.
- **Numbers**: Integers and floats (e.g., `42`, `3.14`).
- **Variables**: Placeholders representing unknown values. They always start with an uppercase letter or an underscore (e.g., `X`, `Parent`, `_temp`).
- **Compound Terms**: Structures composed of a functor (an atom) and a number of arguments (terms) enclosed in parentheses (e.g., `father(tom)`, `point(X, Y, Z)`). The number of arguments is the term's *arity*.

#### Defining Facts
A **fact** asserts an absolute truth in the database. For example:
```prolog
parent(tom, bob).
```
Here, `parent` is a predicate of arity 2 (denoted `parent/2`). This fact states that "tom is a parent of bob". Note that in Prolog, predicates are defined by order-sensitive arguments, and every statement must end with a period (`.`).

#### Writing Rules
A **rule** asserts a conditional truth. Rules consist of a **head** (what we want to prove) and a **body** (the conditions that must be met), separated by the neck operator `:-` (which reads as "if"):
```prolog
grandparent(X, Z) :-
    parent(X, Y),
    parent(Y, Z).
```
This states: "X is a grandparent of Z if X is a parent of Y, and Y is a parent of Z." The comma `,` acts as a logical conjunction (AND).

#### Querying the Knowledge Base
To execute a Prolog program, you run a **query** (or goal) against the database in the interactive REPL. When you input a query like `?- parent(tom, Child).`, the engine searches the database for facts or rules that match, binding variables to values that make the query true.

The companion project **tutorial_basics** demonstrates core Prolog concepts with a family relationships knowledge base. Here is the file **tutorial_basics/prolog/family.pl**:

```prolog
:- module(family, [
    parent/2,
    grandparent/2,
    sibling/2,
    ancestor/2
]).

%% Facts: parent(Parent, Child)
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).

%% Rules
grandparent(X, Z) :-
    parent(X, Y),
    parent(Y, Z).

sibling(X, Y) :-
    parent(Z, X),
    parent(Z, Y),
    X \= Y.

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :-
    parent(X, Z),
    ancestor(Z, Y).
```

## Unification and Pattern Matching

At the heart of Prolog is **unification**, which generalizes pattern matching. Two terms unify if they are identical, or if they contain variables that can be instantiated (bound) in such a way that the terms become identical.

The rules for unification are straightforward:
1. **Constants**: An atom or number unifies only with itself (e.g., `apple = apple` succeeds, but `apple = orange` fails).
2. **Variables**: An uninstantiated variable can unify with any term. Once unified, the variable is bound to that term (e.g., `X = apple` succeeds and binds `X` to `apple`). If two variables unify (e.g., `X = Y`), they become co-referenced or aliased; binding one immediately binds the other.
3. **Compound Terms**: Two compound terms unify if they share the same functor and arity, and all of their corresponding arguments unify recursively (e.g., `point(1, Y) = point(X, 5)` succeeds by binding `X = 1` and `Y = 5`).

Let's look at some examples in the REPL using the unification operator `=`:

```prolog
?- apple = apple.
true.

?- apple = X.
X = apple.

?- parent(tom, X) = parent(tom, bob).
X = bob.

?- parent(tom, X) = grandparent(tom, bob).
false.
```

#### The Occurs Check
In mathematical logic, a variable cannot unify with a term that contains that variable (for example, `X = f(X)`). Checking for this is called the **occurs check**.
By default, most Prolog implementations (including SWI-Prolog) omit the occurs check during standard unification for efficiency reasons. This can occasionally lead to circular/infinite terms:

```prolog
?- X = f(X).
X = f(X).  % Creates a cyclic term
```

If you require strict logical correctness, you can perform unification with the occurs check explicitly:

```prolog
?- unify_with_occurs_check(X, f(X)).
false.
```

## Backtracking and Search

Prolog resolves queries by performing a **depth-first search** of the state space defined by your database. It evaluates goals from left to right and tries clauses from top to bottom. When a sub-goal fails, Prolog automatically backtracks to the most recent decision point (or *choice point*), retracts any variable bindings made since that point, and tries the next alternative.

#### Tracing Backtracking
Consider the query `?- grandparent(tom, ann).` using the `family.pl` module:
1. Prolog matches the query against the head of the rule `grandparent(X, Z) :- parent(X, Y), parent(Y, Z).`, binding `X = tom` and `Z = ann`.
2. It evaluates the first sub-goal: `parent(tom, Y)`.
3. Scanning the database from top to bottom, it finds the first match: `parent(tom, bob).`, binding `Y = bob`.
4. It sets a choice point (since `parent(tom, liz)` is another possible match for the first sub-goal).
5. It evaluates the second sub-goal: `parent(bob, ann).`.
6. This matches a fact in the database, so the query succeeds.

If the second sub-goal had failed (e.g., if we queried `?- grandparent(tom, pat).` and no match was found for the second sub-goal), Prolog would backtrack to the choice point at step 4, bind `Y = liz`, and attempt to prove `parent(liz, pat)`.

#### Controlling Search with the Cut (`!`)
The **cut** operator, written as `!`, is a built-in predicate that always succeeds but has a crucial side effect: it discards all choice points created since the parent goal was matched. Once execution passes a cut, you cannot backtrack past it to try alternative clauses or alternative bindings for variables to the left of the cut.

Cuts are generally categorized into two types:
- **Green Cuts**: Used solely to optimize performance by pruning search paths that are known to lead to failure. They do not change the logical meaning of the program.
- **Red Cuts**: Alter the logical behavior of the program. If you remove a red cut, the program will yield different (and often incorrect) answers.

#### Negation as Failure (`\+`)
Prolog operates under the **Closed World Assumption**: anything that cannot be proven true from the database is assumed to be false. Consequently, Prolog implements negation using **Negation as Failure** (NAF), represented by the operator `\+`.

The query `\+ Goal` succeeds if and only if `Goal` fails to prove:

```prolog
?- \+ parent(tom, ann).
true.
```

*(Note that `\+` does not mean "logically false"; it means "not provable". If a variable is uninstantiated inside a negation, it may not behave as expected because NAF is not constructive. It is best practice to ensure variables inside `\+ Goal` are already bound before the check.)*

## Lists and Recursive Data Structures

Lists are a primary data structure in Prolog. A list is an ordered sequence of terms enclosed in square brackets (e.g., `[apple, banana, cherry]`). The empty list is written as `[]`.

#### Head and Tail Notation
A non-empty list can be split into two parts:
- **Head**: The first element of the list.
- **Tail**: A list containing all subsequent elements.

This is written using the vertical bar constructor: `[Head | Tail]`. For example:
- In the list `[apple, banana, cherry]`, the Head is `apple`, and the Tail is `[banana, cherry]`.
- Unifying `[X | Y] = [apple]` binds `X = apple` and `Y = []`.

#### Recursive List Processing
Since lists are defined recursively, they are processed using recursion. The standard pattern consists of:
1. **Base Case**: The stopping condition, typically specifying the behavior when the list is empty (`[]`).
2. **Recursive Case**: Processing the head of the list, then calling the predicate recursively on the tail (`T`).

The **tutorial_basics** project includes hand-rolled list utilities that mirror the built-in predicates. Here is the file **tutorial_basics/prolog/lists.pl**:

```prolog
:- module(my_lists, [
    my_length/2,
    my_member/2,
    my_append/3,
    my_reverse/2,
    my_last/2
]).

%% Length of a list
my_length([], 0).
my_length([_|T], N) :-
    my_length(T, N1),
    N is N1 + 1.

%% Membership
my_member(X, [X|_]).
my_member(X, [_|T]) :- my_member(X, T).

%% Append
my_append([], L, L).
my_append([H|T], L, [H|R]) :-
    my_append(T, L, R).

%% Reverse using accumulator
my_reverse(List, Reversed) :-
    my_reverse(List, [], Reversed).
my_reverse([], Acc, Acc).
my_reverse([H|T], Acc, Reversed) :-
    my_reverse(T, [H|Acc], Reversed).

%% Last element
my_last([X], X).
my_last([_|T], X) :- my_last(T, X).
```

## Arithmetic and Comparison

In Prolog, arithmetic expressions are stored as compound terms rather than being evaluated automatically. For example, `1 + 2` is structurally the term `+(1, 2)`.

To evaluate an arithmetic expression, you must use the **`is/2`** operator:

```prolog
?- X = 1 + 2.
X = 1 + 2.    % Structural unification, no evaluation

?- X is 1 + 2.
X = 3.        % Evaluates expression on the right and unifies with X
```

> [!IMPORTANT]
> The right-hand side of `is/2` must be fully instantiated (contain no free variables) at the time of evaluation, otherwise Prolog will throw an `instantiation_error`.

#### Term Comparison vs. Arithmetic Comparison
Prolog distinguishes between matching structure, verifying term identity, and comparing numerical values:
- **`=`**: Unification (binds variables if possible).
- **`==`**: Strict term equivalence (checks if terms are identical without binding variables).
- **`\==`**: Strict term non-equivalence.
- **`=:=`**: Arithmetic equality (evaluates both sides numerically and compares results).
- **`=\=`**: Arithmetic inequality.

Example:
```prolog
?- 1 + 2 == 2 + 1.
false.        % Structurally different terms

?- 1 + 2 =:= 2 + 1.
true.         % Both evaluate to 3
```

Other numerical comparison operators evaluate both sides before comparing: `<`, `>`, `=<` (less than or equal), and `>=` (greater than or equal).

## Input and Output

Prolog provides basic input and output predicates to interact with the console and files.

#### Printing Terms
- **`write/1`**: Prints a term to the current output stream.
- **`nl/0`**: Outputs a newline character.
- **`format/2`**: Provides formatted output similar to `printf` in other languages. It takes a template string and a list of arguments:
  ```prolog
  ?- format('Hello ~w, the result is ~d.~n', [world, 42]).
  Hello world, the result is 42.
  true.
  ```
  Common format descriptors:
  - `~w`: Write the term (using standard formatting).
  - `~q`: Quote the term if necessary (so it can be read back by `read/1`).
  - `~d`: Print an integer.
  - `~n`: Output a newline.

#### Reading Input
- **`read/1`**: Reads the next Prolog term from the stream. The term entered by the user must end with a period (`.`) and a newline.
  ```prolog
  ?- read(X).
  |: parent(tom, bob).
  X = parent(tom, bob).
  ```

#### File Input and Output
To read from or write to a file, you open a stream, perform operations, and close the stream:

```prolog
read_file(Path) :-
    open(Path, read, Stream),
    read_terms(Stream),
    close(Stream).

read_terms(Stream) :-
    read(Stream, Term),
    (   Term == end_of_file
    ->  true
    ;   format('Read term: ~w~n', [Term]),
        read_terms(Stream)
    ).
```

## Modules and Code Organization

As a codebase grows, naming collisions become a significant risk. SWI-Prolog implements a module system to encapsulate code.

#### Defining a Module
At the top of your Prolog source file, declare the module name and list the public predicates that are exported:

```prolog
:- module(math_utils, [
    add/3,
    square/2
]).
```

All predicates not listed in the module declaration remain private to that file and cannot be called from outside the module.

#### Importing a Module
To load and use predicates from another module, use `use_module/1` or `use_module/2`:

```prolog
% Import a library module
:- use_module(library(lists)).

% Import a local module using a relative file path
:- use_module(math_utils).
```

You can also selectively import specific predicates to avoid polluting your namespace:

```prolog
:- use_module(library(lists), [member/2, append/3]).
```

## Definite Clause Grammars (DCGs) — A First Look

Definite Clause Grammars (DCGs) are a built-in Prolog syntax designed for parsing and generating sequences (most commonly lists of tokens or characters). DCGs provide a clean, readable notation that automatically translates into standard Prolog clauses using **difference lists**.

#### Difference Lists
A difference list represents a list as the difference between two lists: a starting list and a remainder list (written as `List1 - List2`). This allows list concatenation in $O(1)$ time without calling `append/3`.

#### DCG Syntax (`-->`)
Instead of the standard neck operator `:-`, DCG rules use `-->`. The compiler automatically adds two hidden arguments representing the difference list input and output.

For example, this simple grammar rule:
```prolog
sentence --> noun_phrase, verb_phrase.
```
Is compiled internally into:
```prolog
sentence(Start, End) :-
    noun_phrase(Start, Mid),
    verb_phrase(Mid, End).
```

#### Parsing and Generating
To test or run a DCG, use the built-in **`phrase/2`** or **`phrase/3`** predicate:

```prolog
sentence --> [the], [cat], [sat].

?- phrase(sentence, [the, cat, sat]).
true.
```
We will explore DCGs extensively in the Natural Language Processing (NLP) chapter.

## Common SWI-Prolog Built-in Predicates

SWI-Prolog includes a rich set of built-in predicates for control flow, database manipulation, term inspection, and list processing. Here is a reference table of the most common predicates:

| Predicate | Description | Example Query & Result |
| :--- | :--- | :--- |
| `findall(Template, Goal, List)` | Finds all solutions matching `Goal` and collects `Template` values into `List`. Returns empty list if no solutions. | `?- findall(C, parent(tom, C), List).` <br> `List = [bob, liz].` |
| `bagof(Template, Goal, List)` | Like `findall/3`, but groups results by free variables and fails if there are no solutions. | `?- bagof(C, parent(P, C), List).` <br> `P = bob, List = [ann, pat] ; P = tom, List = [bob, liz].` |
| `setof(Template, Goal, Set)` | Like `bagof/3`, but sorts the resulting list and removes duplicates. | `?- setof(C, parent(P, C), Set).` <br> `P = bob, Set = [ann, pat].` |
| `asserta(Clause)` | Dynamically asserts `Clause` at the *beginning* of the database. | `?- asserta(parent(tom, sam)).` <br> `true.` |
| `assertz(Clause)` | Dynamically asserts `Clause` at the *end* of the database. | `?- assertz(parent(tom, sam)).` <br> `true.` |
| `retract(Clause)` | Dynamically removes the first clause matching `Clause` from the database. | `?- retract(parent(tom, bob)).` <br> `true.` |
| `retractall(Head)` | Removes all clauses whose head unifies with `Head`. | `?- retractall(parent(tom, _)).` <br> `true.` |
| `functor(Term, Functor, Arity)` | Unifies with the name and arity of a compound term (or creates one). | `?- functor(parent(tom, bob), F, A).` <br> `F = parent, A = 2.` |
| `arg(N, Term, Argument)` | Accesses the N-th argument of a compound term. | `?- arg(2, parent(tom, bob), Arg).` <br> `Arg = bob.` |
| `Term =.. List` | The "univ" operator; converts a compound term to/from a list of functor and arguments. | `?- parent(tom, bob) =.. L.` <br> `L = [parent, tom, bob].` |
