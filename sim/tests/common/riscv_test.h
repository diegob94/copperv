#ifndef RISCV_TEST_H
#define RISCV_TEST_H

#include "encoding.h"

#define RVTEST_RV32U
#define RVTEST_RV32M
#define RVTEST_RV32S
// Register for test identification in monitor
#define TESTNUM x28

#define RVTEST_CODE_BEGIN \
  .global TEST_NAME; \
TEST_NAME:

#define T_ADDR 0x80000000
#define O_ADDR 0x80000004
#define TC_ADDR 0x80000008
#define T_PASS 0x01000001
#define T_FAIL 0x02000001

#define RVTEST_PASS \
    loop_pass: \
    li t1, T_PASS;  \
    li t2, T_ADDR;  \
    sw t1, 0(t2); \
    jal zero, loop_pass;

#define RVTEST_FAIL \
    loop_fail: \
    li t1, T_FAIL;  \
    li t2, T_ADDR;  \
    sw t1, 0(t2); \
    jal zero, loop_fail;

#define RVTEST_CODE_END

#define RVTEST_DATA_BEGIN .balign 4;
#define RVTEST_DATA_END

#endif // RISCV_TEST_H