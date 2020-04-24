MEMORY {
	mem : ORIGIN = 0x00000000, LENGTH = 0x0000ffff + 1
}

SECTIONS {
  .text : { *(.text) } > mem
  .data : { *(.data) } > mem
  .bss : { *(.bss) } > mem
}
