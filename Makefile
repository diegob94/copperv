
PYTHON ?= $(if $(shell which python),python,python3)
SHELL = bash
RTL_SOURCES = $(realpath $(COPPERV_RTL) $(TOP_RTL))
LOGS_DIR = work/logs

COPPERV_RTL = 	rtl/copperv/copperv.v \
				rtl/copperv/control_unit.v \
				rtl/copperv/execution.v \
				rtl/copperv/idecoder.v \
				rtl/copperv/register_file.v

COPPERV_INCLUDES = rtl/include

TOP_RTL = 	rtl/top.v \
			rtl/uart/wb2uart.v \
			rtl/memory/sram_32_sp.v \
			rtl/wishbone/wb_adapter.v \
			rtl/wishbone/wb_copperv.v \
			rtl/wishbone/wb_sram.v \
			rtl/external_ip/wb2axip/rtl/wbxbar.v \
			rtl/external_ip/wb2axip/rtl/skidbuffer.v \
			rtl/external_ip/wb2axip/rtl/addrdecode.v

space := $(subst ,, )
comma := $(subst ,,,)

var2toml = $(addprefix $(1)=[\n,$(addsuffix \n]\n,$(subst $(space),$(comma)\n,$(patsubst %,"%",$($(1))))))

rtl/files.toml:
	$(info Generating $@)
	@printf '$(call var2toml,COPPERV_RTL)' > $@
	@printf '$(call var2toml,TOP_RTL)' >> $@
	@printf '$(call var2toml,COPPERV_INCLUDES)' >> $@

getvar-%:
	$(info $($*))
	@true

.PHONY: all
all: work/sim/result.xml

.PHONY: clean
clean:
	rm -rf work/sim

.PHONY: setup
setup: .venv
	mkdir -p $(LOGS_DIR)
	git submodule init
	git submodule update

.venv:
	$(PYTHON) -m venv .venv
	source .venv/bin/activate; pip install -r requirements.txt

work/sim/result.xml: $(RTL_SOURCES) $(shell find ./sim -name '*.py') rtl/external_ip/wb2axip | setup
	source .venv/bin/activate; pytest -v -n $(shell nproc) --junitxml="$@" $(PYTEST_OPTS)

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

