# Reinforcement Learning – Prolog Source Code

This directory contains Prolog implementations of the **Overview of Reinforcement Learning** chapter examples.

## Running

Requires [SWI-Prolog](https://www.swi-prolog.org/) (`swipl`).

```bash
swipl -g main -t halt mdp_demo.pl
swipl -g main -t halt frozen_lake_qlearning.pl
```

## Files

- **mdp_demo.pl** — Markov Decision Process examples: a 3×3 grid world solved with Value Iteration and Policy Iteration, plus a Forest Management problem
- **frozen_lake_qlearning.pl** — Q-learning agent trained on a self-contained 4×4 FrozenLake grid world (deterministic transitions, no Gymnasium dependency)

## Architecture

Both examples implement reinforcement learning algorithms entirely in pure SWI-Prolog:

### MDP Demo (`mdp_demo.pl`)

- **Grid world**: 9 states (3×3), 4 actions (↑→↓←), deterministic transitions
  - State 8 (goal): +10 reward
  - State 5 (trap): -5 reward
- **Value Iteration**: iterates the Bellman optimality equation `V(s) = max_a [R(s,a) + γ Σ P(s'|s,a)·V(s')]`
- **Policy Iteration**: alternates policy evaluation (solve for V under current policy) and policy improvement (greedy update)
- **Forest Management**: 5 age-class states, Wait/Cut actions, fire probability 0.1

### Q-Learning (`frozen_lake_qlearning.pl`)

- **FrozenLake 4×4** environment implemented directly (no external libraries)
  - S=start, F=frozen (safe), H=hole (terminal, reward=0), G=goal (terminal, reward=1)
- **Q-table** stored in SWI-Prolog global state via `nb_setval`/`nb_getval`
- **Epsilon-greedy** exploration with exponential decay
- **Q-update**: `Q(s,a) ← Q(s,a) + α [r + γ·max_{a'} Q(s',a') − Q(s,a)]`
- Prints the learned policy as a 4×4 arrow grid
