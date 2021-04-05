#include "riscv_test.h"

.section .init, "ax"
.global _start
_start:
    .cfi_startproc
    .cfi_undefined ra
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    la sp, __stack_top
    add s0, sp, zero
#ifdef ISA_TEST
#define TEST(n) \
    .global n; \
    jal zero,n; \
    .global n ## _ret; \
    n ## _ret:

    TEST(simple)
    TEST(add)
    TEST(addi)
    TEST(and)
    TEST(andi)
    TEST(auipc)
    TEST(beq)
    TEST(bge)
    TEST(bgeu)
    TEST(blt)
    TEST(bltu)
    TEST(bne)
    TEST(fence_i)
    TEST(jal)
    TEST(jalr)
    TEST(lb)
    TEST(lbu)
    TEST(lh)
    TEST(lhu)
    TEST(lui)
    TEST(lw)
    TEST(or)
    TEST(ori)
    TEST(sb)
    TEST(sh)
    TEST(sll)
    TEST(slli)
    TEST(slt)
    TEST(slti)
    TEST(sltiu)
    TEST(sltu)
    TEST(sra)
    TEST(srai)
    TEST(srl)
    TEST(srli)
    TEST(sub)
    TEST(sw)
    TEST(xor)
    TEST(xori)
    li t1, T_PASS;  \
    li t2, T_ADDR;  \
    sw t1, 0(t2);
#endif
#ifdef ENTRY_POINT
    jal zero, ENTRY_POINT
#endif
    .cfi_endproc
    .end

