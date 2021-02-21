#!/bin/bash
set -v

gcc=/home/diegob/cad/riscv/toolchain_multilib/bin/riscv64-unknown-elf-gcc

$gcc -march=rv32i -mabi=ilp32 -Wl,-T,/home/diegob/projects/copperv/sim/tests/common/linker.ld,--strip-debug,-Bstatic -nostdlib -ffreestanding test.c -o test.o

$gcc -march=rv32i -mabi=ilp32 -Wl,-T,/home/diegob/projects/copperv/sim/tests/common/linker.ld,--strip-debug,-Bstatic -nostdlib -ffreestanding -lgcc test.c -o test.o

$gcc -march=rv32i -mabi=ilp32 -Wl,-T,/home/diegob/projects/copperv/sim/tests/common/linker.ld,--strip-debug,-Bstatic -ffreestanding -nostartfiles test.c -o test.o


#/home/diegob/cad/riscv/toolchain_multilib/bin/riscv64-unknown-elf-gcc -Wl,-T,/home/diegob/projects/copperv/sim/tests/common/linker.ld,--strip-debug,-Bstatic -nostdlib -ffreestanding -lgcc -v /home/diegob/projects/copperv/work/test_dhrystone/crt0.o /home/diegob/projects/copperv/work/test_dhrystone/copperv.o /home/diegob/projects/copperv/work/test_dhrystone/syscalls.o /home/diegob/projects/copperv/work/test_dhrystone/dhrystone.o /home/diegob/projects/copperv/work/test_dhrystone/dhrystone_main.o -o /home/diegob/projects/copperv/work/test_dhrystone/dhrystone.elf

#/home/diegob/cad/riscv/toolchain_multilib/bin/riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -lgcc -v  -I/home/diegob/projects/copperv/sim/tests/common  -I/home/diegob/projects/copperv/sim/tests/common/c  -I/home/diegob/projects/copperv/sim/tests/dhrystone -MD -MF /home/diegob/projects/copperv/work/test_dhrystone/dhrystone_main.o.d -c /home/diegob/projects/copperv/sim/tests/dhrystone/dhrystone_main.c -o /home/diegob/projects/copperv/work/test_dhrystone/dhrystone_main.o


