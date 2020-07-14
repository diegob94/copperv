#include "riscv_test.h"

    li t1, T_PASS    # Test passed code
    li t2, T_ADDR    # Test result address
    li t3, 101       # Number A
    li t4, 202       # Number B
    add t5, t3, t4   # A + B
    li t3, 303       # Reference result 101 + 202 = 303
    sub t6, t5, t3   # Check result
    beqz t6, finish  # Test passed!
    li t1, T_FAIL    # Test failed code
finish:
    sw t1, 0(t2)     # Output test results
loop:
    j loop

