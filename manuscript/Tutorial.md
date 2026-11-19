# Prolog Tutorial

This chapter introduces Prolog to readers new to logic programming. It covers the ideas you need for the AI applications in later chapters.

{width: "80%"}
![Architecture diagram for the Tutorial Basics example](FIG_tutorial_basics.jpg)

## Facts, Rules, and Queries

Prolog, short for *Programming in Logic*, is based on a subset of first-order predicate calculus. In imperative languages you specify *how* to compute something. Prolog is declarative: you describe *what* is true (the facts and rules of a problem domain) and let Prolog deduce the answers to your queries.

A Prolog program is built from **terms**:
- **Atoms**: Constants that name objects or relations. They start with a lowercase letter (e.g., `tom`, `bob`, `parent`) or sit inside single quotes (e.g., `'New York'`).
- **Numbers**: Integers and floats (e.g., `42`, `3.14`).
- **Variables**: Stand for unknown values. They start with an uppercase letter or an underscore (e.g., `X`, `Parent`, `_temp`).
- **Compound Terms**: A functor (an atom) followed by arguments in parentheses (e.g., `father(tom)`, `point(X, Y, Z)`). The number of arguments is the term's *arity*.

#### Defining Facts
A **fact** states something that is always true. For example:
```prolog
parent(tom, bob).
```
Here, `parent` is a predicate of arity 2 (written `parent/2`). This fact states that "tom is a parent of bob". Argument order matters: `parent(bob, tom)` means something else. Every clause ends with a period (`.`).

#### Writing Rules
A **rule** states something that is true when its conditions hold. A rule has a **head** (what we want to prove) and a **body** (the conditions), joined by the `:-` operator, which reads as "if":
```prolog
grandparent(X, Z) :-
    parent(X, Y),
    parent(Y, Z).
```
This reads: "X is a grandparent of Z if X is a parent of Y, and Y is a parent of Z." The comma `,` means AND.

#### Querying the Knowledge Base
To run a Prolog program, you type a **query** (or goal) in the REPL. For a query like `?- parent(tom, Child).`, Prolog searches the database for facts and rules that match and binds variables to values that make the query true.

The project **tutorial_basics** shows these ideas with a family relationships database. Here is the file **tutorial_basics/prolog/family.pl**:

```prolog
:- module(family, [
    parent/2,
    grandparent/2,
    sibling/2,
    ancestor/2,
    ancestor_within/3
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

%% ancestor(+X, -Y) / ancestor(X, Y)
%%
%% WARNING: this naive transitive closure is safe only for acyclic
%% `parent/2` data. If the data contains a cycle (e.g. by mistake a
%% person is their own ancestor) or if the rules were written in the
%% left-recursive form `ancestor(X,Z), parent(Z,Y)`, queries would not
%% terminate. Use ancestor_within/3 for a depth-bounded, always
%% terminating variant.
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :-
    parent(X, Z),
    ancestor(Z, Y).

%% ancestor_within(+X, -Y, +MaxDepth)
%% Depth-bounded ancestor search: yields each ancestor of X found
%% within MaxDepth parent/2 steps. Terminates even for cyclic data.
ancestor_within(X, Y, MaxDepth) :-
    MaxDepth > 0,
    parent(X, Z),
    (   Y = Z
    ;   MaxDepth1 is MaxDepth - 1,
        ancestor_within(Z, Y, MaxDepth1)
    ).
```

`ancestor_within/3` limits the search depth, so it always terminates, even on cyclic `parent/2` data. Try these queries after loading the project with `swipl load.pl`:

```prolog
?- grandparent(tom, Who).
Who = ann ;
Who = pat ;
false.

?- ancestor_within(tom, Who, 1).
Who = bob ;
Who = liz ;
false.
```

## Unification and Pattern Matching

At the heart of Prolog is **unification**, a general form of pattern matching. Two terms unify if they are identical, or if binding their variables can make them identical.

The rules are:
1. **Constants**: An atom or number unifies only with itself (e.g., `apple = apple` succeeds, but `apple = orange` fails).
2. **Variables**: An unbound variable unifies with any term and becomes bound to it (e.g., `X = apple` binds `X` to `apple`). If two variables unify (e.g., `X = Y`), they share a value: binding one binds the other.
3. **Compound Terms**: Two compound terms unify if they have the same functor and arity and their arguments unify pair by pair (e.g., `point(1, Y) = point(X, 5)` binds `X = 1` and `Y = 5`).

Here are some examples in the REPL using the unification operator `=`:

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
In logic, a variable cannot unify with a term that contains it (for example, `X = f(X)`). The test for this is the **occurs check**.
Most Prolog systems, SWI-Prolog included, skip the occurs check for speed. This can create cyclic terms:

```prolog
?- X = f(X).
X = f(X).  % Creates a cyclic term
```

If you need sound unification, call the occurs check version:

```prolog
?- unify_with_occurs_check(X, f(X)).
false.
```

## Backtracking and Search

Prolog answers a query with a **depth-first search** over the clauses in your database. It runs goals from left to right and tries clauses from top to bottom. When a goal fails, Prolog backtracks to the most recent *choice point*, undoes the variable bindings made since then, and tries the next option.

#### Tracing Backtracking
Consider the query `?- grandparent(tom, ann).` using the `family.pl` module:
1. Prolog matches the query against the head of the rule `grandparent(X, Z) :- parent(X, Y), parent(Y, Z).`, binding `X = tom` and `Z = ann`.
2. It runs the first goal, `parent(tom, Y)`.
3. Scanning from the top, it finds `parent(tom, bob)` and binds `Y = bob`. Since `parent(tom, liz)` could also match, Prolog leaves a choice point.
4. It runs the second goal, `parent(bob, ann)`.
5. This matches a fact, so the query succeeds.

Now consider `?- grandparent(tom, joe).`, where no one is a parent of `joe`. With `Y = bob`, the goal `parent(bob, joe)` fails. Prolog backtracks to the choice point from step 3, binds `Y = liz`, and tries `parent(liz, joe)`. That fails too, and no choice points remain, so the query fails.

#### Controlling Search with the Cut (`!`)
The **cut**, written `!`, always succeeds but has a side effect: it removes all choice points made since the current clause was chosen. After a cut, Prolog cannot backtrack into other clauses of the same predicate or into goals to the left of the cut.

There are two kinds of cut:
- **Green cuts** only prune branches that would fail anyway. They make code faster without changing its answers.
- **Red cuts** change the program's answers. Remove a red cut and the program gives different (often wrong) results.

Here is a `max/3` predicate with a green cut and one with a red cut:

```prolog
% Green: the second clause tests X < Y, so the cut only saves work.
max_green(X, Y, X) :- X >= Y, !.
max_green(X, Y, Y) :- X < Y.

% Red: the second clause has no test, so it relies on the cut.
max_red(X, Y, X) :- X >= Y, !.
max_red(_, Y, Y).
```

The red version gives a wrong answer for `max_red(5, 2, 2)`: the first clause does not match because `5` does not unify with `2`, so Prolog never reaches the cut and the second clause succeeds.

#### Negation as Failure (`\+`)
Prolog uses the **Closed World Assumption**: anything it cannot prove from the database it treats as false. So Prolog's negation is **Negation as Failure** (NAF), written `\+`.

The query `\+ Goal` succeeds if and only if Prolog cannot prove `Goal`:

```prolog
?- \+ parent(tom, ann).
true.
```

`\+` means "not provable", not "logically false". NAF never binds variables, so a goal with unbound variables inside `\+` can give surprising answers. Bind the variables before the test:

```prolog
?- \+ parent(X, ann).
false.        % someone is a parent of ann

?- member(X, [tom, liz]), \+ parent(X, ann).
X = tom ;
X = liz.
```

## Lists and Recursive Data Structures

Lists are Prolog's main data structure. A list is a sequence of terms in square brackets (e.g., `[apple, banana, cherry]`). The empty list is `[]`.

#### Head and Tail Notation
A non-empty list has two parts:
- **Head**: The first element.
- **Tail**: A list of the remaining elements.

The vertical bar splits a list: `[Head | Tail]`. For example:
- In the list `[apple, banana, cherry]`, the Head is `apple`, and the Tail is `[banana, cherry]`.
- Unifying `[X | Y] = [apple]` binds `X = apple` and `Y = []`.

#### Recursive List Processing
A list is a recursive structure, so we process it with recursion. The usual pattern has two clauses:
1. **Base case**: Handles the empty list (`[]`) and stops.
2. **Recursive case**: Handles the head, then calls the predicate on the tail.

The **tutorial_basics** project writes its own versions of common list predicates. Here is the file **tutorial_basics/prolog/lists.pl**:

```prolog
%% lists.pl - List processing examples
%% Demonstrates: head/tail, recursion, list predicates
%%
%% NOTE: this file is named lists.pl, but its module is `my_lists`.
%% Keeping the module name `my_lists` (rather than `lists`) is a
%% deliberate workaround: naming a module `lists` shadows SWI-Prolog's
%% own library(lists), which breaks library(plunit) and library(clpfd)
%% (they depend on library(lists) internally).  All public predicates
%% keep their original names and arities (my_length/2 etc.).

:- module(my_lists, [
    my_length/2,
    my_member/2,
    my_append/3,
    my_reverse/2,
    my_last/2
]).

:- use_module(library(clpfd)).

%% my_length(?List, ?N) - bidirectional length using CLP(FD)
%% Works in both directions: my_length([a,b,c], 3) succeeds, and
%% my_length(L, 3) binds L to a list of three fresh variables.
my_length(List, N) :-
    N #>= 0,
    my_length_(List, N).

my_length_([], 0).
my_length_([_|T], N) :-
    N #> 0,
    N1 #= N - 1,
    my_length_(T, N1).

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

Because `my_length/2` uses CLP(FD) constraints, it works in both directions: `my_length([a,b,c], N)` binds `N = 3`, and `my_length(L, 3)` binds `L` to a list of three fresh variables. `my_reverse/3` uses an *accumulator*: it moves each head onto the front of `Acc`, so the reversed list builds up in one linear pass.

## Arithmetic and Comparison

Prolog does not evaluate arithmetic expressions on its own. `1 + 2` is just the compound term `+(1, 2)`.

To evaluate an expression, use the **`is/2`** operator:

```prolog
?- X = 1 + 2.
X = 1 + 2.    % Structural unification, no evaluation

?- X is 1 + 2.
X = 3.        % Evaluates expression on the right and unifies with X
```

W> The right side of `is/2` must have no unbound variables when it runs, or Prolog throws an `instantiation_error`. Constraints from `library(clpfd)` are the exception: they accept unbound variables and wait until enough is known, which is why `my_length/2` above works in both directions.

#### Term Comparison vs. Arithmetic Comparison
Prolog has separate operators for unification, term identity, and numeric comparison:
- **`=`**: Unification (binds variables if it can).
- **`==`**: Identity (true if the terms are identical, without binding variables).
- **`\==`**: Not identical.
- **`=:=`**: Numeric equality (evaluates both sides and compares).
- **`=\=`**: Arithmetic inequality.

Example:
```prolog
?- 1 + 2 == 2 + 1.
false.        % Structurally different terms

?- 1 + 2 =:= 2 + 1.
true.         % Both evaluate to 3
```

The other numeric comparisons also evaluate both sides: `<`, `>`, `=<` (less than or equal), and `>=` (greater than or equal). Note the spelling `=<`, not `<=`.

## Input and Output

Prolog has predicates for console and file input and output.

#### Printing Terms
- **`write/1`**: Prints a term to the current output stream.
- **`nl/0`**: Outputs a newline character.
- **`format/2`**: Formatted output, like `printf` in other languages. It takes a format string and a list of arguments:
  ```prolog
  ?- format('Hello ~w, the result is ~d.~n', [world, 42]).
  Hello world, the result is 42.
  true.
  ```
  Common format directives:
  - `~w`: Write the term.
  - `~q`: Write the term with quotes where needed, so `read/1` can read it back.
  - `~d`: Print an integer.
  - `~n`: Output a newline.

#### Reading Input
- **`read/1`**: Reads the next Prolog term from input. The term must end with a period (`.`) followed by white space.
  ```prolog
  ?- read(X).
  |: parent(tom, bob).
  X = parent(tom, bob).
  ```

#### File Input and Output
To read or write a file, you open a stream, use it, and close it. The file **tutorial_basics/prolog/file_io.pl** reads every term in a file:

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

`read/2` returns the atom `end_of_file` when no terms remain, which ends the recursion. The same file defines `read_file_terms/2`, which collects the terms into a list instead of printing them. It wraps the work in `setup_call_cleanup/3`, which closes the stream even if a syntax error interrupts the read:

```prolog
read_file_terms(Path, Terms) :-
    setup_call_cleanup(
        open(Path, read, Stream),
        collect_terms(Stream, Terms),
        close(Stream)).

collect_terms(Stream, Terms) :-
    read(Stream, Term),
    (   Term == end_of_file
    ->  Terms = []
    ;   Terms = [Term|Rest],
        collect_terms(Stream, Rest)
    ).
```

Try it on the sample data file:

```prolog
?- read_file_terms('data/people.pl', Terms).
Terms = [person(tom, 62), person(bob, 38), likes(bob, chess)].
```

## Modules and Code Organization

As a code base grows, predicate names start to clash. SWI-Prolog's module system keeps each file's names apart.

#### Defining a Module
At the top of a source file, declare the module name and list the predicates it exports:

```prolog
:- module(math_utils, [
    add/3,
    square/2
]).
```

Predicates not in the export list are private to the module. (Code outside can still call them with an explicit module prefix such as `math_utils:helper(X)`, but you should treat them as private.)

#### Importing a Module
To load another module and use its predicates, call `use_module/1` or `use_module/2`:

```prolog
% Import a library module
:- use_module(library(lists)).

% Import a local module using a relative file path
:- use_module(math_utils).
```

You can also import only the predicates you need:

```prolog
:- use_module(library(lists), [member/2, append/3]).
```

## Definite Clause Grammars (DCGs), A First Look

Definite Clause Grammars (DCGs) are a built-in Prolog notation for parsing and generating sequences, most often lists of tokens or characters. Prolog translates DCG rules into ordinary clauses that use **difference lists**.

#### Difference Lists
A difference list represents a list as the difference between two lists: a full list and the part left over (often written `List1-List2`). For example, `[a, b, c | T]-T` stands for `[a, b, c]`. Because the tail `T` is an unbound variable, you can append to the list in `O(1)`$ time by binding `T`, with no call to `append/3`.

#### DCG Syntax (`-->`)
DCG rules use `-->` instead of `:-`. The compiler adds two hidden arguments to each rule: the input list and the list left over after parsing.

For example, this grammar rule:
```prolog
sentence --> noun_phrase, verb_phrase.
```
compiles into:
```prolog
sentence(Start, End) :-
    noun_phrase(Start, Mid),
    verb_phrase(Mid, End).
```

#### Parsing and Generating
To run a DCG, call **`phrase/2`** or **`phrase/3`**:

```prolog
sentence --> [the], [cat], [sat].

?- phrase(sentence, [the, cat, sat]).
true.
```
The Natural Language Processing chapter covers DCGs in depth.

## Common SWI-Prolog Built-in Predicates

SWI-Prolog has many built-in predicates for control, changing the database, inspecting terms, and processing lists. This table lists common ones. The `asserta`, `assertz`, and `retract` examples use a `likes/2` predicate declared with `:- dynamic likes/2.`, because Prolog raises a permission error if you change a static predicate such as `parent/2`.

| Predicate | Description | Example Query & Result |
| :--- | :--- | :--- |
| `findall(Template, Goal, List)` | Collects `Template` for every solution of `Goal` into `List`. Gives `[]` if there are none. | `?- findall(C, parent(tom, C), List).` <br> `List = [bob, liz].` |
| `bagof(Template, Goal, List)` | Like `findall/3`, but groups results by free variables and fails if there are no solutions. | `?- bagof(C, parent(P, C), List).` <br> `P = bob, List = [ann, pat] ; P = tom, List = [bob, liz].` |
| `setof(Template, Goal, Set)` | Like `bagof/3`, but sorts the list and removes duplicates. | `?- setof(C, parent(P, C), Set).` <br> `P = bob, Set = [ann, pat] ; P = tom, Set = [bob, liz].` |
| `asserta(Clause)` | Adds `Clause` before the other clauses of its predicate. | `?- asserta(likes(tom, tea)).` <br> `true.` |
| `assertz(Clause)` | Adds `Clause` after the other clauses of its predicate. | `?- assertz(likes(tom, jazz)).` <br> `true.` |
| `retract(Clause)` | Removes the first clause that unifies with `Clause`. | `?- retract(likes(tom, tea)).` <br> `true.` |
| `retractall(Head)` | Removes all clauses whose head unifies with `Head`. | `?- retractall(likes(tom, _)).` <br> `true.` |
| `functor(Term, Functor, Arity)` | Gets the name and arity of a term, or builds a term from them. | `?- functor(parent(tom, bob), F, A).` <br> `F = parent, A = 2.` |
| `arg(N, Term, Argument)` | Gets the N-th argument of a compound term. | `?- arg(2, parent(tom, bob), Arg).` <br> `Arg = bob.` |
| `Term =.. List` | The "univ" operator: converts between a term and a list of its functor and arguments. | `?- parent(tom, bob) =.. L.` <br> `L = [parent, tom, bob].` |

## Optional Practice Problems

1. **Aunts, Uncles, and Cousins**: Add `parent(liz, joe).` to `family.pl`, then write `aunt_or_uncle/2` and `cousin/2` using `parent/2` and `sibling/2`. Add tests to `tests/test_family.pl` that check `cousin(ann, joe)` succeeds and `cousin(ann, pat)` fails.
2. **Nth Element and Flatten**: In `lists.pl`, write `my_nth1/3` (the N-th element of a list, counting from 1) and `my_flatten/2` (which turns `[a, [b, [c]], d]` into `[a, b, c, d]`). Add tests to `tests/test_lists.pl`.
3. **Write Terms to a File**: Add `write_file_terms(+Path, +Terms)` to `file_io.pl`. Use `portray_clause/2` so each term ends with a period, then check that `read_file_terms/2` reads back the same list.
