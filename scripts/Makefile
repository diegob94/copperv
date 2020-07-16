SHELL = bash

#ROOT = $(realpath ../)
ROOT = ..
SCRIPTS = $(ROOT)/scripts
RTL = $(ROOT)/rtl
SIM = $(ROOT)/sim
UTIL = $(ROOT)/util

RTL_SOURCES = $(wildcard $(RTL)/*.v)
SIM_SOURCES = $(wildcard $(SIM)/*.v) $(wildcard $(SIM)/*.sv)
STD_OVL = $(UTIL)/std_ovl
TEST = test_0

ICARUSFLAGS = -I$(STD_OVL) -y$(STD_OVL) -I$(RTL)/include -I$(SIM)/include -Wall -Wno-timescale -g2012
VVPFLAGS = -lxt2 
ifdef DEBUG
ICARUSFLAGS += -pfileline=1
VVPFLAGS += +DUMP_REGFILE
endif
GTKWAVEFLAGS = --rcvar 'splash_disable on' -A -a $(SCRIPTS)/tb.gtkw 

.PHONY: all
all: sim

# Test compile
include $(SCRIPTS)/test.mk

.PHONY: test_all
test_all:
	$(SCRIPTS)/unit_test.py

sim.vvp: $(RTL_SOURCES) $(SIM_SOURCES) $(TEST).hex $(TEST).hex_dump 
	iverilog $(ICARUSFLAGS) -o $@ $(RTL_SOURCES) $(SIM_SOURCES) |& tee sim_compile.log

.PHONY: sim
sim: sim.vvp 
	vvp $< +HEX_FILE=$(TEST).hex $(VVPFLAGS) |& tee sim_run_$(TEST).log

.PHONY: lint
lint: $(RTL_SOURCES)
	verilator --lint-only -Wall -Wpedantic $(RTL_SOURCES) -I$(RTL)/include

.PHONY: wave
wave:
	gtkwave tb.lxt $(GTKWAVEFLAGS)

.PHONY: clean
clean:
	rm -fv sim.vvp

.PHONY: clean_all
clean_all: clean clean_test
	rm -fv sim_run_*.log sim_compile.log tb.lxt

