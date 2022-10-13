
PYTHON ?= $(if $(shell which python),python,python3)
SHELL = bash
RTL_SOURCES = $(shell find ./rtl -name '*.v')
LOGS_DIR = work/logs

.PHONY: all
all: work/sim/result.xml

.PHONY: clean
clean:
	rm -rf work/sim

.PHONY: setup
setup: .venv
	mkdir -p $(LOGS_DIR)

.venv:
	pip install --user pipenv
	pipenv install

work/sim/result.xml: $(RTL_SOURCES) $(shell find ./sim -name '*.py') work/top.config | setup
	pytest -v -n $(shell nproc) --junitxml="$@" $(PYTEST_OPTS)

work/top.json: $(RTL_SOURCES) scripts/fpga.ys | setup
	yosys -s scripts/fpga.ys |& tee $(LOGS_DIR)/yosys_fpga.log

work/top.config: work/top.json scripts/ulx3s_v20.lpf | setup
	nextpnr-ecp5 --package CABGA381 --85k --json work/top.json \
		--lpf scripts/ulx3s_v20.lpf --textcfg $@ --write work/top.nextpnr.json
	yosys -p "read_json work/top.nextpnr.json; write_verilog -noattr work/top.nextpnr.v"

work/ulx3s.bit: work/top.config | setup 
	ecppack $< $@

.PHONY: program
program: work/ulx3s.bit | setup
	openFPGALoader -b ulx3s $<

