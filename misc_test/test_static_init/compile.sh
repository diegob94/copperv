#!/bin/bash
set -v

#$gcc -march=rv32i -mabi=ilp32 -Wl,-T,/home/diegob/projects/copperv/sim/tests/common/linker.ld,--strip-debug,-Bstatic -nostdlib -ffreestanding test.c -o test.o

#$gcc -march=rv32i -mabi=ilp32 -Wl,-T,/home/diegob/projects/copperv/sim/tests/common/linker.ld,--strip-debug,-Bstatic -nostdlib -ffreestanding -lgcc test.c -o test.o

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -Wl,-T,linker.ld,--strip-debug,-Bstatic,-Map,output.map -ffreestanding -nostartfiles test.c -o test.o
../../scripts/monitor_utils.py dissassemble test.o -o test.D -objdump riscv64-unknown-elf-objdump
riscv64-unknown-elf-objcopy -O verilog test.o test.hex
riscv64-unknown-elf-objcopy -O binary test.o test.bin

cat test.hex

xxd test.bin | tee test.bin.ascii

xxd test.o > test.o.ascii

riscv64-unknown-elf-objdump -h test.o

cat test.c

cat test.D

riscv64-unknown-elf-readelf -S test.o

