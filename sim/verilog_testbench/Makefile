.PHONY: all
all: run

TEST ?= dhrystone
ROOT_DIR := $(realpath ../..)

include $(ROOT_DIR)/scripts/variables.mk

TOPLEVEL = tb
VERILOG_SOURCES = $(addprefix $(ROOT_DIR)/,$(COPPERV_RTL)) \
    testbench.v fake_memory.v
COMPILE_ARGS=-I$(ROOT_DIR)/$(COPPERV_INCLUDES) -Iinclude
TESTS_DIR=$(ROOT_DIR)/sim/tests
TEST_DIR=$(TESTS_DIR)/$(TEST)
HEX_FILE=$(TEST_DIR)/$(TEST).hex
override PLUSARGS += +HEX_FILE=$(HEX_FILE) +disable_timeout
#override PLUSARGS += +debug_testbench
export MAKE = make CXX=g++-10

.PHONY: $(HEX_FILE)
$(HEX_FILE):
	$(MAKE) -C $(TEST_DIR)

.PHONY: clean
clean:
	rm -rfv obj_dir *.vcd *.log

.PHONY: obj_dir/sim
obj_dir/sim:
	verilator -Wall -Wno-fatal --threads $(shell nproc) $(COMPILE_ARGS) -o $(notdir $@) --trace-fst --top-module $(TOPLEVEL) --exe --build --no-timing --cc sim_main.cpp $(VERILOG_SOURCES) 

.PHONY: run
run: obj_dir/sim $(HEX_FILE)
	date
	./obj_dir/sim $(PLUSARGS)
	date
	@echo
	@echo fake_uart:
	@cat fake_uart.log

