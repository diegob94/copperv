
PYTHON ?= $(if $(shell which python),python,python3)
SHELL = bash
RTL_SOURCES = $(shell find ./rtl -name '*.v')

.PHONY: all
all: work/sim/result.xml work/top.json

.PHONY: clean
clean:
	rm -rf work/sim

.venv:
	pip install --user pipenv
	pipenv install

work/sim/result.xml: .venv $(RTL_SOURCES) $(shell find ./sim -name '*.py')
	pytest -v -n $(shell nproc) --junitxml="$@" $(PYTEST_OPTS)

work/top.json: $(RTL_SOURCES) scripts/fpga.ys
	yosys -s scripts/fpga.ys

