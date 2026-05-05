# Makefile for sudoku_solver - Constraint-based Sudoku solver
# Usage: make [all|run|test]

SWIPL = swipl

.PHONY: all run test tests

all: run test

run:
	@echo "=== Running sudoku_solver examples ==="
	$(SWIPL) -g " \
	  Puzzle = [[5,3,_,_,7,_,_,_,_], \
	            [6,_,_,1,9,5,_,_,_], \
	            [_,9,8,_,_,_,_,6,_], \
	            [8,_,_,_,6,_,_,_,3], \
	            [4,_,_,8,_,3,_,_,1], \
	            [7,_,_,_,2,_,_,_,6], \
	            [_,6,_,_,_,_,2,8,_], \
	            [_,_,_,4,1,9,_,_,5], \
	            [_,_,_,_,8,_,_,7,9]], \
	  sudoku(Puzzle), print_board(Puzzle), halt" -s load.pl

test:
	@echo "=== Running sudoku_solver tests ==="
	$(SWIPL) -g "['tests/test_sudoku.pl'], run_tests, halt" -s load.pl

tests: test
