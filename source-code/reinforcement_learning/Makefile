run:
	swipl -g main -t halt mdp_demo.pl
	swipl -g main -t halt frozen_lake_qlearning.pl

test:
	swipl -g "set_random(seed(42)), run_tests, halt(0)" -s tests/test_rl.pl
