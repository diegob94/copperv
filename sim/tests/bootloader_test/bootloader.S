#define BOOTLOADER_MAGIC_ADDR (0x1000-4)

.section .boot, "ax"
la t5, _start // mem (application) region start address
li t0, BOOTLOADER_MAGIC_ADDR // magic address for reading app code
lw t1, 0(t0) // read program length in bytes
li t3, 0 // loop index
loop:
add t4, t3, t5 // target address = loop index + mem region start address
lw t2, 0(t0) // read program word
sw t2, 0(t4) // store program word
addi t3, t3, 4 // increment index
bgtu t1, t3, loop // check if loop done
jal zero, _start // jump to crto (start uploaded code execution)

