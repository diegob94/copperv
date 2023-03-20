
.section .init, "ax"

// initialize C stack
la sp, __stack_top
mv s0, sp

call _start

