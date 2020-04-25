
LINKER_SCRIPT = ../sim/alfa_test/test.ld
TOOLCHAIN = ~/riscv/toolchain/bin/riscv32-unknown-elf-
CC = $(TOOLCHAIN)gcc
CFLAGS = -Wl,-T,$(LINKER_SCRIPT) -nostdlib
all: sim

fw.elf: ../sim/alfa_test/test_0.S
	@echo CC $(CC)
	$(CC) $(CFLAGS) $< -o $@

fw.hex: fw.elf
	$(TOOLCHAIN)objcopy -O verilog $< $@

chi1.vvp: fw.hex
	iverilog -o $@ ../rtl/copperv.v ../sim/testbench.v

sim: chi1.vvp
	vvp $<

clean:
	rm -fv chi1.vvp
