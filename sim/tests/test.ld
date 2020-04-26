MEMORY {
	mem : ORIGIN = 0x00000000, LENGTH = 0x000000ff + 1
}

SECTIONS {
	.memory : {
		. = 0x000000;
		start*(.text);
		*(.text);
		*(*);
		end = .;
		. = ALIGN(4);
                FILL(0x0);
                . = LENGTH(mem);
	} > mem
}
