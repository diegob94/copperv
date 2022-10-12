
PYTHON ?= $(if $(shell which python),python,python3)
SHELL = bash
RTL_SOURCES = $(shell find ./rtl -name '*.v')

.PHONY: all
all: work/sim/result.xml

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

work/top.config: work/top.json scripts/ulx3s_v20.lpf
	nextpnr-ecp5 --package CABGA381 --85k --json work/top.json \
		--lpf scripts/ulx3s_v20.lpf --textcfg $@ --write work/top.nextpnr.json
	yosys -p "read_json work/top.nextpnr.json; write_verilog -noattr work/top.nextpnr.v"

work/ulx3s.bit: work/top.config
	ecppack $< $@

.PHONY: program
program: work/ulx3s.bit
	openFPGALoader -b ulx3s $<

