SHELL = bash

#ROOT = $(realpath ../)
ROOT = ..
SCRIPTS = $(ROOT)/scripts
RTL = $(ROOT)/rtl
SIM = $(ROOT)/sim
UTIL = $(ROOT)/util

RTL_SOURCES := $(wildcard $(RTL)/*.v)
SIM_SOURCES := $(wildcard $(SIM)/*.v) $(wildcard $(SIM)/*.sv) 
HEADER_SOURCES := $(wildcard $(RTL)/include/*.v) $(wildcard $(SIM)/include/*.v)
STD_OVL = $(UTIL)/std_ovl
TEST = test_0

ICARUSFLAGS = -I$(STD_OVL) -y$(STD_OVL) -I$(RTL)/include -I$(SIM)/include -Wall -Wno-timescale -g2012
VVPFLAGS = -M. 
PLUSARGS = -lxt2
ifdef DEBUG
ICARUSFLAGS += -pfileline=1
PLUSARGS += +DUMP_REGFILE
endif
GTKWAVEFLAGS = --rcvar 'splash_disable on' -A -a $(SCRIPTS)/tb.gtkw 
VERILATORFLAGS = --lint-only -Wall -Wpedantic -I$(RTL)/include

.PHONY: all
all: sim

# Test compile
include $(SCRIPTS)/test.mk

.PHONY: test_all
test_all: clean_all lint
	$(SCRIPTS)/unit_test.py

sim.vvp: $(RTL_SOURCES) $(SIM_SOURCES) $(HEADER_SOURCES) $(SIM)/copperv_tools.sft copperv_tools.vpi
	iverilog $(ICARUSFLAGS) $(RTL_SOURCES) $(SIM_SOURCES) -o $@ 2>&1 | tee sim_compile.log

$(SIM)/include/monitor_utils_h.v: $(RTL)/include/copperv_h.v $(SCRIPTS)/monitor_utils.py
	$(SCRIPTS)/monitor_utils.py -monitor $@ $(RTL)/include/copperv_h.v

copperv_tools.vpi: $(SIM)/copperv_tools.c
	iverilog-vpi $<

copperv.synth.json: $(RTL_SOURCES) $(HEADER_SOURCES)
	yosys -p "read_verilog -I$(RTL)/include $(RTL_SOURCES); synth -top copperv; write_json $@"

.PHONY: synth_check
synth_checks: copperv.synth.json
	$(SCRIPTS)/find_latches.py $<

.PHONY: sim
sim: sim.vvp $(TEST).hex $(TEST).D
	vvp $(VVPFLAGS) -mcopperv_tools $< +HEX_FILE=$(TEST).hex +DISS_FILE=$(TEST).D $(PLUSARGS) 2>&1 | tee sim_run_$(TEST).log

.PHONY: lint
lint: $(RTL_SOURCES) $(SCRIPTS)/waivers.vlt
	verilator $(VERILATORFLAGS) $(SCRIPTS)/waivers.vlt $(RTL_SOURCES) 2>&1 | tee lint.log 
	! grep -q '^%Error:' lint.log

.PHONY: wave
wave:
	gtkwave tb.lxt $(GTKWAVEFLAGS)

.PHONY: clean
clean:
	rm -fv copperv_tools.o copperv_tools.vpi
	rm -fv sim.vvp

.PHONY: clean_all
clean_all: clean clean_test
	rm -fv sim_run_*.log sim_compile.log tb.lxt unit_test_*.log
