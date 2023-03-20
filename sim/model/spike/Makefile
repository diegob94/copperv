
.PHONY: all
all: run

CC = riscv64-unknown-elf-gcc
RISCV = /home/diegob/eda/riscv32-unknown-elf

hello_world.elf: hello_world.c
	$(CC) -march=rv32i -mabi=ilp32 $< -o $@
	../../../scripts/utils.py debug hello_world.elf

.PHONY: run
run: hello_world.elf
	spike --isa=RV32I -l $(RISCV)/bin/pk hello_world.elf 2>spike.log

.PHONY: clean
clean:
	rm -rf hello_world.elf spike.log
