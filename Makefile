
PYTHON ?= $(if $(shell which python),python,python3)
SHELL = bash

.PHONY: all
all: work/sim/result.xml

.PHONY: clean
clean:
	rm -rf work/sim

.venv:
	pip install --user pipenv
	pipenv install

work/sim/result.xml: .venv $(shell find ./rtl -name '*.v') $(shell find ./sim -name '*.py')
	pytest -v -n $(shell nproc) --junitxml="$@" $(PYTEST_OPTS)

