.PHONY: all sim gui clean
all: sim

SCRIPTS = ../scripts
RTL = ../rtl
SIM = ../sim
LINKER_SCRIPT = ../sim/tests/test.ld
TOOLCHAIN = ../util/toolchain/bin/riscv32-unknown-elf-
STD_OVL = ../util/std_ovl
CC = $(TOOLCHAIN)gcc
ICARUSFLAGS = -I$(STD_OVL) -y$(STD_OVL)
VVPFLAGS = -lxt2
LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i

VERILOG_SOURCES = $(wildcard $(RTL)/*.v) $(wildcard $(SIM)/*.v)
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

sim.vvp: $(VERILOG_SOURCES)
	iverilog $(ICARUSFLAGS) -o $@ $(VERILOG_SOURCES)

sim: sim.vvp fw.hex fw.D fw.hex_dump
	vvp $< +FW_FILE=fw.hex $(VVPFLAGS)

gui: sim
	gtkwave tb.lxt --rcvar 'splash_disable on' -A

clean:
	rm -fv *.vvp *.D *.hex *.elf *.hex_dump $(OBJS) $(DISS)
