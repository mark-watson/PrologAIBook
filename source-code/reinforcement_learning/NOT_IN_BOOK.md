# This example is not yet in the book.

Status: working, self-contained demos — both examples run standalone via
`make run` (MDP value/policy iteration and Q-learning FrozenLake) and the
plunit suite is `make test`.  Coverage in the manuscript is still pending.

Run with SWI-Prolog:

```bash
swipl -g main -t halt mdp_demo.pl
swipl -g main -t halt frozen_lake_qlearning.pl
```
