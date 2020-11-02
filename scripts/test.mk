SHELL = bash

SDK = $(ROOT)/sdk
LINKER_SCRIPT = $(SDK)/linker.ld

TOOLCHAIN = riscv64-unknown-elf-
CC      = $(TOOLCHAIN)gcc
OBJDUMP = $(TOOLCHAIN)objdump
OBJCOPY = $(TOOLCHAIN)objcopy

LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i -mabi=ilp32 -I$(SDK) -I$(SIM_DIR)/include
# -I$(RISCV_TESTS)/isa/macros/scalar

ASM_FILES = $(wildcard $(TEST_DIR)/*.S)
OBJ_FILES = $(ASM_FILES:.S=.o)

TEST = $(shell basename $(TEST_DIR))

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
#	$(TOOLCHAIN)objcopy -O elf32-littleriscv -R .riscv.attributes $@

%.E: %.S
	$(CC) $(CFLAGS) -E -c $< -o $@
	grep -Ev '^#|^$$' $@ | tr ';' '\n' > $(notdir $@)

%.E: %.c
	$(CC) $(CFLAGS) -E -c $< -o $@

$(TEST).elf: $(OBJ_FILES) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $(OBJ_FILES) -o $@

$(TEST).hex: $(TEST).elf $(TEST).D
	$(OBJCOPY) -O verilog $< $@

#%.D: %.elf
#	$(SCRIPTS)/dissassembly.py $<
#
#%.D: %.o
#	$(SCRIPTS)/dissassembly.py $<

