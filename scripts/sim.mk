.PHONY: all gui clean
all: sim

SCRIPTS = ../scripts
RTL = ../rtl
SIM = ../sim
LINKER_SCRIPT = ../sim/tests/test.ld
TOOLCHAIN = ../util/toolchain/bin/riscv32-unknown-elf-
STD_OVL = ../util/std_ovl
GTKWAVEFLAGS = --rcvar 'splash_disable on' -A 
CC = $(TOOLCHAIN)gcc
ICARUSFLAGS = -I$(STD_OVL) -y$(STD_OVL) -I$(RTL)/include -I$(SIM)/include -Wall -Wno-timescale -g2012
VVPFLAGS = -lxt2
LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i

RTL_SOURCES = $(wildcard $(RTL)/*.v)
SIM_SOURCES = $(wildcard $(SIM)/*.v)
VERILOG_SOURCES = $(RTL_SOURCES) $(SIM_SOURCES)
SOURCES = $(SIM)/tests/test_0.S
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

sim.vvp: $(VERILOG_SOURCES) $(SIM)/include/magic_numbers_h.v 
	iverilog $(ICARUSFLAGS) -o $@ $(VERILOG_SOURCES)

design.rtl: $(RTL_SOURCES)
	iverilog $(ICARUSFLAGS) -o $@ $^ -E

$(SIM)/include/magic_numbers_h.v: $(RTL)/include/copperv_h.v
	$(SCRIPTS)/magic_numbers.py -monitor $@ $<

.PHONY: sim
sim: sim.vvp fw.hex fw.D fw.hex_dump
	vvp $< +FW_FILE=fw.hex $(VVPFLAGS)

gui: sim
	gtkwave tb.lxt $(GTKWAVEFLAGS)

clean:
	rm -fv *.vvp *.D *.hex *.elf *.hex_dump $(OBJS) $(DISS)
