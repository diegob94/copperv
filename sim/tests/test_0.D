
../sim/tests/test_0.o:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <finish-0x28>:
   0:	075bd337          	lui	t1,0x75bd
   4:	d1530313          	addi	t1,t1,-747 # 75bcd15 <loop+0x75bcce9>
   8:	02100393          	addi	t2,zero,33
   c:	06500e13          	addi	t3,zero,101
  10:	0ca00e93          	addi	t4,zero,202
  14:	01de0f33          	add	t5,t3,t4
  18:	12f00e13          	addi	t3,zero,303
  1c:	41cf0fb3          	sub	t6,t5,t3
  20:	000f8463          	beq	t6,zero,28 <finish>
  24:	00000313          	addi	t1,zero,0

00000028 <finish>:
  28:	0063a023          	sw	t1,0(t2)

0000002c <loop>:
  2c:	0000006f          	jal	zero,2c <loop>
