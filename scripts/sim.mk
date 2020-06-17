.PHONY: all
all: sim
SHELL = /bin/bash

SCRIPTS = ../scripts
RTL = ../rtl
SIM = ../sim
UTIL = ../util
RISCV_TEST = $(UTIL)/riscv-tests
LINKER_SCRIPT = ../sim/tests/test.ld
TOOLCHAIN = ../util/toolchain/bin/riscv32-unknown-elf-
STD_OVL = ../util/std_ovl
CC = $(TOOLCHAIN)gcc

ICARUSFLAGS = -I$(STD_OVL) -y$(STD_OVL) -I$(RTL)/include -I$(SIM)/include -Wall -Wno-timescale -g2012
ICARUSFLAGS += -pfileline=1
VVPFLAGS = -lxt2 
#VVPFLAGS += +DUMP_REGFILE
GTKWAVEFLAGS = --rcvar 'splash_disable on' -A 
LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i -I. -I$(RISCV_TEST)/isa/macros/scalar

RTL_SOURCES = $(wildcard $(RTL)/*.v)
SIM_SOURCES = $(wildcard $(SIM)/*.v) $(wildcard $(SIM)/*.sv)
VERILOG_SOURCES = $(RTL_SOURCES) $(SIM_SOURCES)
SOURCES = $(SIM)/tests/test_0.S
#SOURCES = $(RISCV_TEST)/isa/rv32ui/simple.S
OBJS = $(SOURCES:.S=.o)
DISS = $(SOURCES:.S=.D)

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
	$(TOOLCHAIN)objcopy -O elf32-littleriscv -R .riscv.attributes $@

fw.elf: $(OBJS) $(DISS) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $< -o $@

fw.hex: fw.elf
	$(TOOLCHAIN)objcopy -O verilog $< $@

fw.D: fw.elf
	$(TOOLCHAIN)objdump -D -Mno-aliases $< > $@

%.D: %.o
	$(TOOLCHAIN)objdump -D -Mno-aliases $< > $@

fw.hex_dump: fw.hex
	$(SCRIPTS)/hex_dump.py $< -o $@

sim.vvp: $(VERILOG_SOURCES) $(SIM)/include/monitor_utils_h.v 
	iverilog $(ICARUSFLAGS) -o $@ $(VERILOG_SOURCES) |& tee sim_compile.log

design.rtl: $(RTL_SOURCES)
	iverilog $(ICARUSFLAGS) -o $@ $^ -E

$(SIM)/include/monitor_utils_h.v: $(RTL)/include/copperv_h.v fw.D $(SCRIPTS)/monitor_utils.py
	$(SCRIPTS)/monitor_utils.py -monitor $@ $(RTL)/include/copperv_h.v fw.D

.PHONY: sim
sim: sim.vvp fw.hex fw.D fw.hex_dump
	vvp $< +FW_FILE=fw.hex $(VVPFLAGS) |& tee sim_run.log

.PHONY: gui
gui:
	gtkwave tb.lxt $(GTKWAVEFLAGS)

.PHONY: clean
clean:
	rm -fv sim.vvp

.PHONY: clean_all
clean_all: clean
	rm -fv sim_run.log sim_compile.log *.D *.hex *.elf *.hex_dump $(OBJS) $(DISS) *.lxt *.rtl
