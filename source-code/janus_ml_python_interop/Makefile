# Makefile for janus_ml - scikit-learn from Prolog via Janus
# Usage: make [all|run|test|venv]
#
# Janus embeds the Python that SWI-Prolog was built with, so the
# virtual environment must use that same Python. For the Homebrew
# build on macOS it is the Command Line Tools Python 3.9
# (/usr/bin/python3), and janus.so finds its framework only through
# DYLD_FRAMEWORK_PATH. On Linux the system python3 is usually right.
# Janus uses the packages of the environment named by VIRTUAL_ENV.

SWIPL  = swipl
PYTHON ?= /usr/bin/python3
VENV   = $(CURDIR)/.venv

ifeq ($(shell uname),Darwin)
JANUS_ENV = DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/Library/Frameworks
endif

RUN_SWIPL = VIRTUAL_ENV=$(VENV) $(JANUS_ENV) $(SWIPL)

.PHONY: all run test tests venv

all: run test

venv: $(VENV)/pyvenv.cfg

$(VENV)/pyvenv.cfg: pyproject.toml
	uv sync --python $(PYTHON)
	@touch $@

run: venv
	@echo "=== Running janus_ml - scikit-learn from Prolog via Janus examples ==="
	@$(RUN_SWIPL) -g "py_classify([[1,0,0],[0,1,1],[1,1,0]], [[0,0],[1,0]], P), format('Decision tree predictions: ~w~n', [P]), py_cluster([[0.0,0.0],[0.1,0.0],[9.0,9.0],[9.1,9.0]], 2, L), format('KMeans cluster labels: ~w~n', [L]), halt" -s load.pl

test: venv
	@echo "=== Running janus_ml - scikit-learn from Prolog via Janus tests ==="
	$(RUN_SWIPL) -g "['tests/test_janus_ml.pl'], run_tests, halt" -s load.pl

tests: test
