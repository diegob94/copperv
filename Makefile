SHELL = bash

export RTL_TOP = mkCopperv1
SIM_TOP = mkCopperv1Tb
BSV_RTL_FILE = $(BSV_DIR)/copperv1.bsv
BSV_SIM_FILE = $(BSV_DIR)/copperv1_tb.bsv

BSC_OPTS += -bdir $(TEMP_DIR) 
BSC_OPTS += -u
BSC_OPTS += -p +:$(BSV_DIR):$(RTL_DIR)

BSC_VERILOG_RTL_OPTS += $(BSC_OPTS)
BSC_VERILOG_RTL_OPTS += -vdir $(VERILOG_RTL_DIR)

BSC_VERILOG_SIM_OPTS += $(BSC_OPTS)
BSC_VERILOG_SIM_OPTS += -vdir $(VERILOG_SIM_DIR)
BSC_VERILOG_SIM_OPTS += -D HEX_FILE="\"$(OBJ_TEST_DIR)/test.hex\""
BSC_VERILOG_SIM_LINK_OPTS += -e $(SIM_TOP)
BSC_VERILOG_SIM_LINK_OPTS += -vsearch +:$(VERILOG_SIM_DIR):$(RTL_DIR)

#BSC_SIM_OPTS += $(BSC_OPTS)
#BSC_SIM_OPTS += -show-range-conflict 
#BSC_SIM_OPTS += -check-assert
#BSC_SIM_OPTS += -sched-dot 
#BSC_SIM_OPTS += -info-dir $(DOC_DIR) 

#SIM_EXEC_OPTS += -V
SIM_EXEC_OPTS += +bscvcd
SIM_EXEC_OPTS += +bsccycle

# Root dir:
ROOT = $(realpath .)
TEST_DIR = $(ROOT)/sim/basic
BSV_DIR  = $(ROOT)/bsv
WORK_DIR = $(ROOT)/work
RTL_DIR  = $(ROOT)/rtl

# Work dir:
TEMP_DIR        = $(WORK_DIR)/tmp
VERILOG_RTL_DIR = $(WORK_DIR)/rtl
DOC_DIR         = $(WORK_DIR)/doc
LOGS_DIR        = $(WORK_DIR)/logs
SIM_DIR         = $(WORK_DIR)/sim

# Simulation
VERILOG_SIM_DIR = $(SIM_DIR)/verilog
SIM_EXEC        = $(SIM_DIR)/sim_$(SIM_TOP)
OBJ_TEST_DIR    = $(SIM_DIR)/tests/$(TEST_NAME)
TEST_NAME       = $(shell basename $(TEST_DIR))

# Synthesis
BSV_FILES = $(wildcard $(BSV_DIR)/*.bsv)
RTL_FILES = $(wildcard $(RTL_DIR)/*.v)
VERILOG_RTL_FILES = $(wildcard $(VERILOG_RTL_DIR)/*.v)

.PHONY: all sim rtl clean
all: rtl sim

$(WORK_DIR):
	test -d $(WORK_DIR) || mkdir $(WORK_DIR)
	test -d $(TEMP_DIR) || mkdir $(TEMP_DIR)
	test -d $(VERILOG_RTL_DIR) || mkdir -p $(VERILOG_RTL_DIR)
	test -d $(VERILOG_SIM_DIR) || mkdir -p $(VERILOG_SIM_DIR)
	test -d $(SIM_DIR) || mkdir $(SIM_DIR)
	test -d $(DOC_DIR) || mkdir $(DOC_DIR)
	test -d $(LOGS_DIR) || mkdir $(LOGS_DIR)

rtl: $(WORK_DIR)
	bsc $(BSC_VERILOG_RTL_OPTS) -verilog $(BSV_RTL_FILE) |& tee $(LOGS_DIR)/bsc_rtl.log

$(SIM_EXEC): $(RTL_FILES) $(BSV_FILES) $(WORK_DIR)
	bsc $(BSC_VERILOG_SIM_OPTS) -verilog $(BSV_SIM_FILE) |& tee $(LOGS_DIR)/bsc_sim.log
	bsc $(BSC_VERILOG_SIM_LINK_OPTS) -verilog -o $@ |& tee $(LOGS_DIR)/bsc_sim_link.log

sim: $(SIM_EXEC) 
	test -d $(OBJ_TEST_DIR) || mkdir -p $(OBJ_TEST_DIR)
	$(MAKE) -f $(ROOT)/scripts/test.mk ROOT=$(ROOT) SRC_DIR=$(TEST_DIR) \
		OBJ_DIR=$(OBJ_TEST_DIR) > $(LOGS_DIR)/test_compile_$(TEST_NAME).log
	cd $(TEMP_DIR) && $(SIM_EXEC) $(SIM_EXEC_OPTS) |& tee $(LOGS_DIR)/sim_run.log

wave:
	gtkwave --autosavename --rcvar "splash_disable on" $(SIM_DIR)/dump.vcd

show: rtl
	yosys -c $(ROOT)/scripts/yosys.tcl $(VERILOG_RTL_FILES) |& tee $(LOGS_DIR)/yosys.log

#iverilog verilog/* -o sim.vvp -y/home/diegob/eda/lib/Verilog
#bsc -sim $(BSC_SIM_OPTS) $(BSV_SIM_FILE)
#bsc -simdir $(SIM_DIR) -sim -e $(SIM_TOP) -o $(SIM_EXEC) $(ELAB_DIR)/*.ba

clean:
	rm -rfv $(WORK_DIR)

