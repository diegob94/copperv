.PHONY: all
all: work/sim/result.xml

PYTHON ?= $(if $(shell which python),python,python3)
SHELL = bash
RTL_SOURCES = $(realpath $(COPPERV_RTL) $(TOP_RTL))
LOGS_DIR = work/logs
WITH_VENV = source .venv/bin/activate;

COPPERV_RTL = 	rtl/copperv/copperv.v \
				rtl/copperv/control_unit.v \
				rtl/copperv/execution.v \
				rtl/copperv/idecoder.v \
				rtl/copperv/register_file.v

COPPERV_INCLUDES = rtl/include

TOP_RTL = 	$(COPPERV_RTL) \
			rtl/top.v \
			rtl/uart/wb2uart.v \
			rtl/memory/sram_1r1w.v \
			rtl/wishbone/wb_adapter.v \
			rtl/wishbone/wb_copperv.v \
			rtl/wishbone/wb_sram.v \
			external_ip/wb2axip/rtl/wbxbar.v \
			external_ip/wb2axip/rtl/skidbuffer.v \
			external_ip/wb2axip/rtl/addrdecode.v

APP_START_ADDR := 0x1000
BOOTLOADER_MAGIC_ADDR := $(APP_START_ADDR)-4
T_ADDR := $(APP_START_ADDR)-8
O_ADDR := $(APP_START_ADDR)-12
TC_ADDR := $(APP_START_ADDR)-16
T_PASS := 0x01000001
T_FAIL := 0x02000001

.PHONY: clean
clean:
	rm -rf work/sim

.PHONY: setup
setup: .venv sim/verilog_testbench/include/magic_constants_h.v sim/magic_constants.toml sim/tests/common/magic_constants.h rtl/files.toml scripts/rtl_sources.tcl
	mkdir -p $(LOGS_DIR)
	git submodule update --init

.venv:
	$(PYTHON) -m venv .venv
	$(WITH_VENV) pip install wheel
	$(WITH_VENV) pip install -r requirements.txt

work/sim/result.xml: $(RTL_SOURCES) $(shell find ./sim -name '*.py') | setup
	$(WITH_VENV) pytest -v -n $(shell nproc) --junitxml="$@" $(PYTEST_OPTS)

work/top.json: $(RTL_SOURCES) scripts/fpga.tcl | setup
	yosys -c scripts/fpga.tcl |& tee $(LOGS_DIR)/yosys_fpga.log

work/top.config: work/top.json scripts/ulx3s_v20.lpf | setup
	nextpnr-ecp5 --package CABGA381 --85k --json work/top.json \
		--lpf scripts/ulx3s_v20.lpf --textcfg $@ --write work/top.nextpnr.json
	yosys -p "read_json work/top.nextpnr.json; write_verilog -noattr work/top.nextpnr.v"

work/ulx3s.bit: work/top.config | setup 
	ecppack $< $@

.PHONY: program
program: work/ulx3s.bit | setup
	openFPGALoader -b ulx3s $<

space := $(subst ,, )
comma := $(subst ,,,)
list2toml = $(addprefix $(1)=[\n,$(addsuffix \n]\n,$(subst $(space),$(comma)\n,$(patsubst %,"%",$($(1))))))
list2tcl = $(addprefix set $(1) {\n,$(addsuffix \n}\n,$(subst $(space),\n,$($(1)))))
var2toml = "$(shell printf '$(1) = 0x%X' $$(($($(1)))))\n"
var2cmacro = "$(shell printf '\#define $(1) 0x%X' $$(($($(1)))))\n"
var2vmacro = "$(shell printf "\\\`define $(1) 32'h%X" $$(($($(1)))))\n"

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

getvar-%:
	$(info $($*))
	@true

