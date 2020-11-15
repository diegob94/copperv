#ifndef RISCV_TEST_H
#define RISCV_TEST_H

#define RVTEST_RV32U
// Register for test identification in monitor
#define TESTNUM x28

#define RVTEST_CODE_BEGIN

#define T_ADDR 0x8000
#define T_PASS 0x01000000
#define T_FAIL 0x02000000

#define RVTEST_PASS \
    li t1, T_PASS;  \
    li t2, T_ADDR;  \
    sw t1, 0(t2);

#define RVTEST_FAIL \
    li t1, T_FAIL;  \
    li t2, T_ADDR;  \
    sw t1, 0(t2);

#define RVTEST_CODE_END

#define RVTEST_DATA_BEGIN
#define RVTEST_DATA_END

#endif // RISCV_TEST_H
