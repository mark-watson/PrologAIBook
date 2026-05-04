# Scryer CLP

Constraint programming examples for Scryer Prolog using CLP(Z). Companion code for the Scryer Prolog chapter.

## Running Examples

Run with Scryer Prolog (not SWI-Prolog):

```shell
scryer-prolog prolog/scryer_constraints.pl
```

```prolog
?- magic_square(Square).
?- send_more_money(Letters).
```

## Running Tests

```shell
scryer-prolog -g "use_module(tests/test_scryer_clp), halt"
```

## Description

Showcases Scryer Prolog's `library(clpz)` (the Scryer equivalent of SWI's `clpfd`) with two classic constraint satisfaction problems. The magic square solver finds a 3×3 grid where all rows, columns, and diagonals sum to 15. The SEND+MORE=MONEY solver is the famous cryptarithmetic puzzle. These examples demonstrate Scryer's ISO-compliant constraint handling and provide a direct comparison point with the SWI-Prolog CLP(FD) examples from earlier chapters.
