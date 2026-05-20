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
