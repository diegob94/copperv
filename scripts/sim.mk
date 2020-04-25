
SCRIPTS = ../scripts
RTL = ../rtl
SIM = ../sim
LINKER_SCRIPT = ../sim/alfa_test/test.ld
TOOLCHAIN = ~/riscv/toolchain/bin/riscv32-unknown-elf-
CC = $(TOOLCHAIN)gcc
CFLAGS = -Wl,-T,$(LINKER_SCRIPT) -nostdlib
all: sim

fw.elf: $(SIM)/tests/test_0.S
	@echo CC $(CC)
	$(CC) $(CFLAGS) $< -o $@

fw.hex: fw.elf
	$(TOOLCHAIN)objcopy -O verilog $< $@

fw.D: fw.elf
	$(TOOLCHAIN)objdump -D $< > $@

fw.hex_dump: fw.hex
	$(SCRIPTS)/hex_dump.py $< -o $@

sim.vvp: fw.hex fw.D fw.hex_dump
	iverilog -o $@ $(RTL)/copperv.v $(SIM)/testbench.v

sim: sim.vvp
	vvp $<

clean:
	rm -fv *.vvp *.D *.hex *.elf *.hex_dump
