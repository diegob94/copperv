SHELL = bash

ROOT = $(realpath ./)
SCRIPTS = $(ROOT)/scripts
RTL_DIR = $(ROOT)/rtl
SIM_DIR = $(ROOT)/sim
LOGS_DIR = $(WORK_DIR)/logs

RTL_FILES := $(wildcard $(RTL_DIR)/*.v)
SIM_FILES := $(wildcard $(SIM_DIR)/*.v) $(wildcard $(SIM_DIR)/*.sv) 
RTL_HEADER_FILES := $(wildcard $(RTL)/include/*.v)
SIM_HEADER_FILES := $(wildcard $(SIM_DIR)/include/*.v) $(SIM_DIR)/include/monitor_utils_h.v
#STD_OVL      = $(UTIL)/std_ovl
TEST_DIR     = $(ROOT)/sim/basic
OBJ_TEST_DIR = $(WORK_DIR)/tests/$(TEST_NAME)
TEST_NAME    = $(shell basename $(TEST_DIR))
HEX_FILE  = $(OBJ_TEST_DIR)/test.hex
DISS_FILE = $(OBJ_TEST_DIR)/test.D

#ICARUSFLAGS += -I$(STD_OVL) -y$(STD_OVL)
ICARUSFLAGS += -I$(RTL_DIR)/include -I$(SIM_DIR)/include -Wall -Wno-timescale -g2012
VVPFLAGS += -M. 
VVPFLAGS += -mcopperv_tools
VVPFLAGS += +HEX_FILE=$(HEX_FILE) +DISS_FILE=$(DISS_FILE) $(PLUSARGS)
PLUSARGS += 
ifdef DEBUG
ICARUSFLAGS += -pfileline=1
PLUSARGS += +DUMP_REGFILE
endif
GTKWAVEFLAGS = --rcvar 'splash_disable on' -A -a $(SCRIPTS)/tb.gtkw 
VERILATORFLAGS = --lint-only -Wall -Wpedantic -I$(RTL)/include

all: sim

.PHONY: test
test: clean_all lint_all
	test -d $(OBJ_TEST_DIR) || mkdir -p $(OBJ_TEST_DIR)
	$(MAKE) -f $(ROOT)/scripts/test.mk ROOT=$(ROOT) SRC_DIR=$(TEST_DIR) \
		OBJ_DIR=$(OBJ_TEST_DIR) |& tee $(LOGS_DIR)/test_compile_$(TEST_NAME).log

# Test compile
include $(SCRIPTS)/test.mk

setup:
	test -d $(LOGS_DIR) || mkdir $(LOGS_DIR)
	date > $@

sim.vvp: $(RTL_FILES) $(SIM_FILES) $(RTL_HEADER_FILES) $(SIM_HEADER_FILES) copperv_tools.vpi
	iverilog $(ICARUSFLAGS) $(RTL_FILES) $(SIM_FILES) -o $@ 2>&1 | tee $(LOGS_DIR)/sim_compile.log
	! grep -qF 'error(s) during elaboration.' $(LOGS_DIR)/sim_compile.log

$(SIM_DIR)/include/monitor_utils_h.v: $(RTL)/include/copperv_h.v $(SCRIPTS)/monitor_utils.py
	$(SCRIPTS)/monitor_utils.py -monitor $@ $(RTL)/include/copperv_h.v

copperv_tools.vpi: $(SIM_DIR)/copperv_tools.c $(SIM_DIR)/copperv_tools.sft 
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
sim: sim.vvp test
	vvp $(VVPFLAGS) $< 2>&1 | tee sim_run_$(TEST).log

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

