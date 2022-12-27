.PHONY: all
all: work/sim/result.xml

PYTHON ?= $(if $(shell which python),python,python3)
RTL_SOURCES = $(realpath $(COPPERV_RTL) $(TOP_RTL))
WITH_VENV = source .venv/bin/activate;

include scripts/variables.mk

.PHONY: setup
setup: .venv sim/verilog_testbench/include/magic_constants_h.v sim/magic_constants.toml sim/tests/common/magic_constants.h rtl/files.toml scripts/rtl_sources.tcl
	mkdir -p work/logs
	git submodule update --init

.venv:
	$(PYTHON) -m venv .venv
	$(WITH_VENV) pip install wheel
	$(WITH_VENV) pip install -r requirements.txt

work/sim/result.xml: $(RTL_SOURCES) $(shell find ./sim -name '*.py') | setup
	$(WITH_VENV) pytest -n $(shell nproc) --junitxml="$@" $(PYTEST_OPTS) --durations=0

work/top.json: $(RTL_SOURCES) scripts/fpga.tcl | setup
	yosys -c scripts/fpga.tcl |& tee work/logs/yosys_fpga.log

work/top.config: work/top.json scripts/ulx3s_v20.lpf | setup
	nextpnr-ecp5 --package CABGA381 --85k --json work/top.json \
		--lpf scripts/ulx3s_v20.lpf --textcfg $@ --write work/top.nextpnr.json |& tee work/logs/nextpnr_fpga.log
	yosys -p "read_json work/top.nextpnr.json; write_verilog -noattr work/top.nextpnr.v"

work/ulx3s.bit: work/top.config | setup 
	ecppack $< $@

.PHONY: program
program: work/ulx3s.bit | setup
	openFPGALoader -b ulx3s $<

.PHONY: sim/magic_constants.toml
sim/magic_constants.toml:
	$(info Generating $@)
	@printf $(call var2toml,APP_START_ADDR) > $@
	@printf $(call var2toml,BOOTLOADER_MAGIC_ADDR) >> $@
	@printf $(call var2toml,T_ADDR) >> $@
	@printf $(call var2toml,O_ADDR) >> $@
	@printf $(call var2toml,TC_ADDR) >> $@
	@printf $(call var2toml,T_PASS) >> $@
	@printf $(call var2toml,T_FAIL) >> $@

.PHONY: sim/tests/common/magic_constants.h
sim/tests/common/magic_constants.h:
	$(info Generating $@)
	@printf $(call var2cmacro,APP_START_ADDR) > $@
	@printf $(call var2cmacro,BOOTLOADER_MAGIC_ADDR) >> $@
	@printf $(call var2cmacro,T_ADDR) >> $@
	@printf $(call var2cmacro,O_ADDR) >> $@
	@printf $(call var2cmacro,TC_ADDR) >> $@
	@printf $(call var2cmacro,T_PASS) >> $@
	@printf $(call var2cmacro,T_FAIL) >> $@

.PHONY: sim/verilog_testbench/include/magic_constants_h.v
sim/verilog_testbench/include/magic_constants_h.v:
	$(info Generating $@)
	@printf $(call var2vmacro,APP_START_ADDR) > $@
	@printf $(call var2vmacro,BOOTLOADER_MAGIC_ADDR) >> $@
	@printf $(call var2vmacro,T_ADDR) >> $@
	@printf $(call var2vmacro,O_ADDR) >> $@
	@printf $(call var2vmacro,TC_ADDR) >> $@
	@printf $(call var2vmacro,T_PASS) >> $@
	@printf $(call var2vmacro,T_FAIL) >> $@

.PHONY: rtl/files.toml
rtl/files.toml: $(RTL_SOURCES)
	$(info Generating $@)
	@printf '$(call list2toml,COPPERV_RTL)' > $@
	@printf '$(call list2toml,TOP_RTL)' >> $@
	@printf '$(call list2toml,COPPERV_INCLUDES)' >> $@

.PHONY: scripts/rtl_sources.tcl
scripts/rtl_sources.tcl:
	$(info Generating $@)
	@printf '$(call list2tcl,COPPERV_RTL)' > $@
	@printf '$(call list2tcl,TOP_RTL)' >> $@
	@printf '$(call list2tcl,COPPERV_INCLUDES)' >> $@

