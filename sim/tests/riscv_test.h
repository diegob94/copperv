
#define RVTEST_RV32U
#define TESTNUM x28

#define RVTEST_CODE_BEGIN

#define RVTEST_PASS   \
    li t1, 123456789; \
    li t2, 33;        \
    sw t1, 0(t2);

#define RVTEST_FAIL   \
    li t1, 111111111; \
    li t2, 33;        \
    sw t1, 0(t2);

#define RVTEST_CODE_END

#define RVTEST_DATA_BEGIN
#define RVTEST_DATA_END

