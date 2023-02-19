
.PHONY: all
all: run

CC = riscv64-unknown-elf-gcc
RISCV = /home/diegob/eda/riscv64-unknown-elf

hello_world.elf: hello_world.c
	$(CC) $< -o $@

.PHONY: run
run: hello_world.elf
	spike -l $(RISCV)/bin/pk hello_world.elf 2>spike.log

