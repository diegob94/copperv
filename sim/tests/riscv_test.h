
#define RVTEST_RV32U
#define TESTNUM x28

#define RVTEST_CODE_BEGIN

#define T_ADDR 33<<2
#define T_PASS 123456789
#define T_FAIL 111111111

#define RVTEST_PASS   \
    li t1, T_PASS; \
    li t2, T_ADDR;    \
    sw t1, 0(t2);

#define RVTEST_FAIL   \
    li t1, T_FAIL;    \
    li t2, T_ADDR;    \
    sw t1, 0(t2);

#define RVTEST_CODE_END

#define RVTEST_DATA_BEGIN
#define RVTEST_DATA_END

