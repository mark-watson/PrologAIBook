"""run_popper.py - Run the Popper ILP system on one learning task.

Usage: uv run run_popper.py [TASK_DIR]
TASK_DIR holds bk.pl, exs.pl, and bias.pl (default: this directory).
"""
import os
import sys
from popper.util import Settings, format_prog
from popper.loop import popper


def main():
    kbpath = sys.argv[1] if len(sys.argv) > 1 else '.'
    print(f"Running Popper on the task in {kbpath} ...")
    settings = Settings(
        bk_file=os.path.join(kbpath, 'bk.pl'),
        ex_file=os.path.join(kbpath, 'exs.pl'),
        bias_file=os.path.join(kbpath, 'bias.pl'))
    best_prog, best_score = popper(settings)

    print("\n--- Popper Output ---")
    if best_prog:
        print("Learned program:")
        print(format_prog(best_prog))
        print("Score (tp, fn, tn, fp, size):", best_score)
    else:
        print("No program found that fits the examples.")


if __name__ == '__main__':
    main()
