#include "riscv_test.h"

.global _init
_init:
la  a5,T_ADDR
li  a4,T_PASS
sw   a4,0(a5)
