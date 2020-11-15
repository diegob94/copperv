SHELL = bash -o pipefail

INFO = @echo "`tput setaf 2``tput bold`copperv-make:`tput init`"

ROOT = $(realpath ./)
SCRIPTS = $(ROOT)/scripts
RTL_DIR = $(ROOT)/rtl
SIM_DIR = $(ROOT)/sim
SDK_DIR = $(ROOT)/sdk
LOGS_DIR = $(WORK_DIR)/logs
WORK_DIR = $(ROOT)/work
TEMP_DIR = $(WORK_DIR)/tmp
SIM_BUILD_DIR = $(WORK_DIR)/sim

RTL_FILES := $(wildcard $(RTL_DIR)/*.v)
SIM_FILES := $(wildcard $(SIM_DIR)/*.v) $(wildcard $(SIM_DIR)/*.sv) 
SIM_FILES := $(filter-out %checker_cpu.v, $(SIM_FILES))
RTL_HEADER_FILES := $(wildcard $(RTL_DIR)/include/*.v)
SIM_HEADER_FILES := $(wildcard $(SIM_DIR)/include/*.v) $(MONITOR_UTIL_H)
MONITOR_UTIL_H := $(SIM_BUILD_DIR)/monitor_utils_h.v
TOOLS_VPI := $(SIM_BUILD_DIR)/copperv_tools.vpi
VVP_FILE := $(SIM_BUILD_DIR)/sim.vvp
#STD_OVL      = $(UTIL)/std_ovl
TEST_DIR     = $(SIM_DIR)/tests/simple
OBJ_TEST_DIR = $(SIM_BUILD_DIR)/tests/$(TEST_NAME)
TEST_NAME    = $(shell basename $(TEST_DIR))
HEX_FILE  = $(OBJ_TEST_DIR)/$(TEST_NAME).hex
DISS_FILE = $(OBJ_TEST_DIR)/$(TEST_NAME).D

#ICARUSFLAGS += -I$(STD_OVL) -y$(STD_OVL)
ICARUSFLAGS += -I$(RTL_DIR)/include -I$(SIM_DIR)/include
ICARUSFLAGS += -Wall 
ICARUSFLAGS +=-Wno-timescale
ICARUSFLAGS += -g2012
VVPFLAGS += -M. -mcopperv_tools 
PLUSARGS += +HEX_FILE=$(HEX_FILE) +DISS_FILE=$(DISS_FILE)
ifdef DEBUG
ICARUSFLAGS += -pfileline=1
PLUSARGS += +DUMP_REGFILE
endif
GTKWAVEFLAGS = --rcvar 'splash_disable on' -A -a $(SCRIPTS)/tb.gtkw 
VERILATORFLAGS += --lint-only 
VERILATORFLAGS += -Wall 
VERILATORFLAGS += -Wpedantic 
VERILATORFLAGS += -I$(RTL_DIR)/include

.PHONY: all
all: sim

$(WORK_DIR):
	$(INFO) "Making work directory structure"
	test -d $(WORK_DIR) || mkdir $(WORK_DIR)
	test -d $(LOGS_DIR) || mkdir $(LOGS_DIR)
	test -d $(TEMP_DIR) || mkdir $(TEMP_DIR)
	test -d $(SIM_BUILD_DIR) || mkdir $(SIM_BUILD_DIR)

$(HEX_FILE):
	$(INFO) "Compiling test: $(TEST_DIR)"
	test -d $(OBJ_TEST_DIR) || mkdir -p $(OBJ_TEST_DIR)
	$(MAKE) -f $(ROOT)/scripts/toolchain.mk \
		ROOT=$(ROOT) \
		SRC_DIR=$(TEST_DIR) \
		OBJ_DIR=$(OBJ_TEST_DIR) \
		SDK=$(SDK_DIR) |& tee $(LOGS_DIR)/compile_test_$(TEST_NAME).log

$(MONITOR_UTIL_H): $(RTL_DIR)/include/copperv_h.v $(SCRIPTS)/monitor_utils.py
	cd $(TEMP_DIR); $(SCRIPTS)/monitor_utils.py -monitor $@ $<
	test -d $(SIM_BUILD_DIR)/gtkwave || mkdir $(SIM_BUILD_DIR)/gtkwave
	mv $(TEMP_DIR)/*.gtkwfilter $(SIM_BUILD_DIR)/gtkwave

$(TOOLS_VPI): $(SIM_DIR)/copperv_tools.c $(SIM_DIR)/copperv_tools.sft $(WORK_DIR)
	$(INFO) "Compiling VPI tools"
	cd $(TEMP_DIR); iverilog-vpi $<
	mv $(TEMP_DIR)/copperv_tools.vpi $@

$(VVP_FILE): $(RTL_FILES) $(SIM_FILES) $(RTL_HEADER_FILES) $(SIM_HEADER_FILES) $(TOOLS_VPI)
	$(INFO) "Compiling and linking Verilog simulation"
	cd $(SIM_BUILD_DIR); iverilog $(ICARUSFLAGS) $(RTL_FILES) $(SIM_FILES) -o $@ 2>&1 | tee $(LOGS_DIR)/compile_sim.log
	if grep -qP 'error\(s\) during elaboration.|Include file .*? not found' $(LOGS_DIR)/compile_sim.log; then \
		rm -f $@; \
		false; \
	fi

.PHONY: sim
sim: $(WORK_DIR) $(HEX_FILE) $(MONITOR_UTIL_H) $(VVP_FILE)
	$(INFO) "Running simulation"
	cd $(SIM_BUILD_DIR); vvp $(VVPFLAGS) $(VVP_FILE) $(PLUSARGS) 2>&1 | tee $(LOGS_DIR)/run_sim_$(TEST_NAME).log

.PHONY: lint
lint: $(RTL_FILES) $(SCRIPTS)/waivers.vlt
	verilator $(VERILATORFLAGS) $(SCRIPTS)/waivers.vlt $(RTL_FILES) 2>&1 | tee $(LOGS_DIR)/lint.log 
	! grep -q '^%Error:' $(LOGS_DIR)/lint.log

.PHONY: wave
wake:
	gtkwave tb.lxt $(GTKWAVEFLAGS)

synth: $(SCRIPTS)/yosys.tcl $(WORK_DIR) 
	yosys -c $< 2>&1 | tee ${LOGS_DIR}/$@.log
	! grep -q '^Error' -i ${LOGS_DIR}/$@.log
	date > $@

sta: $(SCRIPTS)/sta.tcl synth $(WORK_DIR)
	sta -exit $< 2>&1 | tee ${LOGS_DIR}/$@.log
	! grep -q '^Error' ${LOGS_DIR}/$@.log
	date > $@

.PHONY: clean
clean:
	rm -rfv $(WORK_DIR)

