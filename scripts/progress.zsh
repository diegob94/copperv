#!/usr/bin/zsh

cat ../util/riscv-opcodes/opcodes-rv32i | grep -Pv '^#|^$' | grep 'beq|addi|add|sub|lui|$' -P --color=auto
