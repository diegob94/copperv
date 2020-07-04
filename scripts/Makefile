SHELL = /usr/bin/zsh

#ROOT = $(realpath ../)
ROOT = ..
SCRIPTS = $(ROOT)/scripts
RTL = $(ROOT)/rtl
SIM = $(ROOT)/sim
UTIL = $(ROOT)/util

RTL_SOURCES = $(wildcard $(RTL)/*.v)
SIM_SOURCES = $(wildcard $(SIM)/*.v) $(wildcard $(SIM)/*.sv)
STD_OVL = $(UTIL)/std_ovl
TEST_NAME = test

ICARUSFLAGS = -I$(STD_OVL) -y$(STD_OVL) -I$(RTL)/include -I$(SIM)/include -Wall -Wno-timescale -g2012
#ICARUSFLAGS += -pfileline=1
VVPFLAGS = -lxt2 
#VVPFLAGS += +DUMP_REGFILE
GTKWAVEFLAGS = --rcvar 'splash_disable on' -A 

.PHONY: all
all: sim

# Test compile
include $(SCRIPTS)/test.mk

sim.vvp: $(RTL_SOURCES) $(SIM_SOURCES) test 
	iverilog $(ICARUSFLAGS) -o $@ $(RTL_SOURCES) $(SIM_SOURCES) |& tee sim_compile.log

.PHONY: sim
sim: sim.vvp 
	vvp $< +HEX_FILE=$(TEST_NAME).hex $(VVPFLAGS) |& tee sim_run_$(TEST_NAME).log

.PHONY: wave
wave:
	gtkwave tb.lxt $(GTKWAVEFLAGS)

.PHONY: clean
clean:
	rm -fv sim.vvp

.PHONY: clean_all
clean_all: clean clean_test
	rm -fv sim_run.log sim_compile.log tb.lxt

