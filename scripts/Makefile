SHELL = bash

#ROOT = $(realpath ../)
ROOT = ..
SCRIPTS = $(ROOT)/scripts
RTL = $(ROOT)/rtl
SIM = $(ROOT)/sim
UTIL = $(ROOT)/util
LOGS_DIR = ./logs

RTL_SOURCES := $(wildcard $(RTL)/*.v)
SIM_SOURCES := $(wildcard $(SIM)/*.v) $(wildcard $(SIM)/*.sv) 
RTL_HEADER_SOURCES := $(wildcard $(RTL)/include/*.v)
SIM_HEADER_SOURCES := $(wildcard $(SIM)/include/*.v) $(SIM)/include/monitor_utils_h.v
STD_OVL = $(UTIL)/std_ovl
TEST = test_0

ICARUSFLAGS = -I$(STD_OVL) -y$(STD_OVL) -I$(RTL)/include -I$(SIM)/include -Wall -Wno-timescale -g2012
VVPFLAGS = -M. 
PLUSARGS = 
ifdef DEBUG
ICARUSFLAGS += -pfileline=1
PLUSARGS += +DUMP_REGFILE
endif
GTKWAVEFLAGS = --rcvar 'splash_disable on' -A -a $(SCRIPTS)/tb.gtkw 
VERILATORFLAGS = --lint-only -Wall -Wpedantic -I$(RTL)/include

all: sim

.PHONY: test
test: clean_all lint_all
	$(SCRIPTS)/unit_test.py

# Test compile
include $(SCRIPTS)/test.mk

setup:
	test -d $(LOGS_DIR) || mkdir $(LOGS_DIR)
	date > $@

sim.vvp: $(RTL_SOURCES) $(SIM_SOURCES) $(RTL_HEADER_SOURCES) $(SIM_HEADER_SOURCES) $(SIM)/copperv_tools.sft copperv_tools.vpi
	iverilog $(ICARUSFLAGS) $(RTL_SOURCES) $(SIM_SOURCES) -o $@ 2>&1 | tee sim_compile.log
	! grep -qF 'error(s) during elaboration.' sim_compile.log

$(SIM)/include/monitor_utils_h.v: $(RTL)/include/copperv_h.v $(SCRIPTS)/monitor_utils.py
	$(SCRIPTS)/monitor_utils.py -monitor $@ $(RTL)/include/copperv_h.v

copperv_tools.vpi: $(SIM)/copperv_tools.c
	iverilog-vpi $<

synth: $(SCRIPTS)/yosys.tcl setup
	yosys -c $< 2>&1 | tee ${LOGS_DIR}/$@.log
	! grep -q '^Error' -i ${LOGS_DIR}/$@.log
	date > $@

sta: $(SCRIPTS)/sta.tcl setup synth
	sta -exit $< 2>&1 | tee ${LOGS_DIR}/$@.log
	! grep -q '^Error' ${LOGS_DIR}/$@.log
	date > $@

.PHONY: synth_checks
synth_checks: sta

.PHONY: sim
sim: sim.vvp $(TEST).hex $(TEST).D
	vvp $(VVPFLAGS) -mcopperv_tools $< +HEX_FILE=$(TEST).hex +DISS_FILE=$(TEST).D $(PLUSARGS) 2>&1 | tee sim_run_$(TEST).log

.PHONY: lint
lint: $(RTL_SOURCES) $(SCRIPTS)/waivers.vlt
	verilator $(VERILATORFLAGS) $(SCRIPTS)/waivers.vlt $(RTL_SOURCES) 2>&1 | tee lint.log 
	! grep -q '^%Error:' lint.log

.PHONY: lint_all
lint_all: lint # synth_checks

.PHONY: wave
wave:
	gtkwave tb.lxt $(GTKWAVEFLAGS)

.PHONY: clean
clean:
	rm -fv copperv_tools.o copperv_tools.vpi
	rm -fv sim.vvp

.PHONY: clean_all
clean_all: clean clean_test
	rm -fv sim_run_*.log sim_compile.log tb.vcd unit_test_*.log copperv.synth.json fake_uart.log

