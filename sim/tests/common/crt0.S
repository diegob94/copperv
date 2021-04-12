#include "riscv_test.h"

#ifndef ENTRY_POINT
#define ENTRY_POINT _init
#endif

.section .init, "ax"
.global _start
_start:
    .cfi_startproc
    .cfi_undefined ra
    .option push
    .option norelax
    // initialize RISCV global pointer
    la gp, __global_pointer$
    .option pop
    // initialize C stack
    la sp, __stack_top
    add s0, sp, zero
    // initialize C BSS section to zero
    .global __BSS_START__
    .global __BSS_END__
    la t0, __BSS_START__
    la t1, __BSS_END__
loop:
    sw zero, 0(t0)
    addi t0, t0, 4
    bgtu t1, t0, loop
    // go to _init or custom entry point
    .global ENTRY_POINT;
    jal zero, ENTRY_POINT
    .cfi_endproc
    .end

