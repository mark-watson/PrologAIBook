# Inductive Logic Programming with Popper

Machine learning is dominated by connectionist methods like deep artificial neural networks. These models learn by updating millions or billions of continuous numerical weights. While neural networks excel at perception tasks (such as computer vision and speech recognition), they suffer from several drawbacks: they require vast amounts of training data, their internal reasoning is opaque (a "black box"), and they cannot easily incorporate existing domain knowledge.

The material for this chapter is derived and inspired by the Popper inductive logic programming system GitHub repository [https://github.com/logic-and-learning-lab/Popper/](https://github.com/logic-and-learning-lab/Popper/).

**Inductive Logic Programming (ILP)** is an alternative approach to machine learning situated at the intersection of machine learning and logic programming. Rather than fitting mathematical functions to numbers, an ILP system learns **symbolic rules** (Prolog programs) directly from:
1. **Background Knowledge (BK)**: Existing facts and rules representing known domain concepts.
2. **Positive Examples**: Examples of the target relationship that the learned program must entail.
3. **Negative Examples**: Examples of the target relationship that the learned program must *not* entail.

The output is a clean, readable Prolog program that fits the training data perfectly. Because the model is represented as logic rules, it is fully explainable, mathematically exact, and can be immediately loaded into a standard Prolog interpreter for verification or execution.


{width: "80%"}
![Architecture diagram for the Inductive Logic Popper example](FIG_inductive_logic_popper.jpg)


## How Popper Works

**Popper** is a state-of-the-art ILP engine. It uses a multi-engine loop:
- **Generation (ASP)**: Popper uses Answer Set Programming (ASP) via the Clingo solver to search the space of possible logic programs and generate candidate hypotheses.
- **Testing (Prolog)**: It uses SWI-Prolog to test if the candidate program entails all positive examples and no negative examples.
- **Feedback (Learning)**: If a candidate program fails (e.g., it is too general and entails a negative example, or too specific and misses a positive one), Popper extracts a symbolic constraint explaining *why* it failed. This constraint is fed back to the ASP solver to prune large portions of the search space, repeating until a minimal, correct solution is found.

---

## The Grandparent Problem Setup

To demonstrate ILP, we want the system to learn the rule defining a `grandparent/2` relationship. We provide background knowledge of family structures, lists of positive grandparent pairings, lists of incorrect pairings, and bias parameters.

### 1. Background Knowledge
We define basic parental relations and genders.

Here is the code in **source-code/inductive_logic_popper/bk.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
parent(pam, bob).
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).
parent(pat, jim).

female(pam).
female(liz).
female(pat).
female(ann).
male(tom).
male(bob).
~~~~~~~~

### 2. Positive & Negative Examples
We supply examples of who is and is not a grandparent.

Here is the code in **source-code/inductive_logic_popper/exs.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
pos(grandparent(pam, ann)).
pos(grandparent(pam, pat)).
pos(grandparent(tom, ann)).
pos(grandparent(tom, pat)).
pos(grandparent(bob, jim)).

neg(grandparent(pam, bob)).
neg(grandparent(tom, liz)).
neg(grandparent(bob, pat)).
neg(grandparent(ann, jim)).
~~~~~~~~

### 3. Search Bias Configuration
To keep the search space finite, we specify the target predicate (the head) and the helper predicates (the body) that Popper is allowed to use to construct candidate rules.

Here is the code in **source-code/inductive_logic_popper/bias.pl**:

{lang="prolog",linenos=off}
~~~~~~~~
head_pred(grandparent, 2).
~~~~~~~~

---

## Python Orchestrator

Popper can be executed as a command-line tool or invoked programmatically inside Python. We construct a script that sets the knowledge-base paths and initiates the solver.

Using a hybrid of Prolog and Python in Popper examples comes down to a deliberate architectural decision: Prolog is the target language and testing engine, but Python is the orchestrator. While the Inductive Logic Programming (ILP) core targets first-order logic, the tool itself is implemented as a modern Python application. The hybrid nature of the examples reflects this clean separation of concerns.

1. Python as the Orchestrator (Glue Code)
The entire multi-engine loop you evaluated earlier (Generation `\rightarrow`$ Testing `\rightarrow`$ Feedback) is written in Python:
- State Management: Python maintains the overall state of the search, handles file I/O, parses command-line arguments, and manages timers.
- Inter-Process Communication: Python acts as the coordinator that calls Clingo (via its Python API or subprocesses) to get a candidate, translates that candidate into a format SWI-Prolog understands, spins up the Prolog interpreter, and parses the results.
- Evaluation Frameworks: In many examples or benchmarks, you will see Python scripts (ilpexp.py or popper.py) managing cross-validation, plotting learning curves, or feeding synthetic data generators into the ILP engine.

2. Prolog as the Relational Data and Representation Layer: even though Python runs the show, the data and the learned rules must be expressed in a logic programming syntax. Therefore, the input files for a Popper problem use standard Prolog format:
- Background Knowledge (bk.pl): Relational data (e.g., parent(amy, bob).) or procedural background knowledge definitions are written natively in Prolog because SWI-Prolog will execute them directly during the test phase.
- Examples (exs.pl): Positive and negative training instances are defined as Prolog facts (e.g., pos(grandparent(amy, charlie)).).
- The Output: The ultimate goal of Popper is to output a crisp, human-readable Prolog program.

Here is the code in **source-code/inductive_logic_popper/run_popper.py**:

{lang="python",linenos=off}
~~~~~~~~
from popper.util import Settings, format_prog
from popper.loop import popper

def main():
    print("Running Popper Inductive Logic Programming solver programmatically...")
    settings = Settings(
        kbpath='.',
        bk_file='bk.pl',
        ex_file='exs.pl',
        bias_file='bias.pl'
    )
    best_prog, best_score = popper(settings)
    
    print("\n--- Popper Output ---")
    if best_prog:
        print("Successfully learned rules:")
        print(format_prog(best_prog))
    else:
        print("No program found that fits the examples.")

if __name__ == '__main__':
    main()
~~~~~~~~

---

## Running the Learning Algorithm

Ensure that you have `uv` installed, then run the python script from the `source-code/inductive_logic_popper` directory:

{linenos=off}
~~~~~~~~
$ uv run run_popper.py
~~~~~~~~

The program will run the ILP loop, outputting the minimal learned Prolog rule that represents the grandparent definition:

{linenos=off}
~~~~~~~~
2.2s Generating partial hypotheses of size: 2
2.2s Generating partial hypotheses of size: 3
2.2s ********************
2.2s New best hypothesis:
2.2s tp:5 fn:0 tn:5 fp:0 size:3
2.2s grandparent(V0,V1):- parent(V0,V2),parent(V2,V1).
2.2s ********************
Running Popper Inductive Logic Programming solver programmatically...

--- Popper Output ---
Successfully learned rules:
grandparent(V0,V1):- parent(V0,V2),parent(V2,V1).
~~~~~~~~

Popper successfully discovered that a grandparent relationship between person `V0` and `V1` holds if `V0` is the parent of some intermediate person `V2`, and `V2` is the parent of `V1`.

---

## Key Design Decisions

**Why Popper?** Many historical ILP systems (like Progol or Aleph) used search heuristics that were prone to local minima, or struggled to scale. Popper solves this by formulating the search as a Constraint Satisfaction Problem. By using Answer Set Programming (Clingo), Popper leverages advanced conflict-driven clause learning solver technology to prune irrelevant logic programs extremely fast.

**Bias and the search space.** ILP is not magic: if we do not guide the search, the space of possible Prolog programs is infinite. The `bias.pl` file is crucial because it limits the search to rules containing only `parent/2` predicates in their bodies. If we added `male/1` or `female/1` to the allowed body predicates, Popper would still find the correct rule, but the search space would expand, requiring more candidates to be evaluated before settling on the minimal program.
