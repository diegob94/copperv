SHELL = bash

SIM_DIR=$(ROOT)/sim
SDK = $(ROOT)/sdk

LINKER_SCRIPT = $(SDK)/linker.ld
TOOLCHAIN = riscv64-unknown-elf-
CC      = $(TOOLCHAIN)gcc
OBJDUMP = $(TOOLCHAIN)objdump
OBJCOPY = $(TOOLCHAIN)objcopy

LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i -mabi=ilp32 -I$(SDK) -I$(SIM_DIR)/include
# -I$(RISCV_TESTS)/isa/macros/scalar

SRC_FILES = $(wildcard $(SRC_DIR)/*.S)
OBJ_FILES = $(OBJ_DIR)/$(notdir $(SRC_FILES:.S=.o))
PREPROC_FILES = $(OBJ_DIR)/$(notdir $(SRC_FILES:.S=.E))

.SUFFIXES:

all: $(OBJ_DIR)/test.hex

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.E: $(SRC_DIR)/%.S
	$(CC) $(CFLAGS) -E -c $< -o $@
	grep -Ev '^#|^$$' $@ | tr ';' '\n' > $@1

$(OBJ_DIR)/test.elf: $(OBJ_FILES) $(PREPROC_FILES) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $(OBJ_FILES) -o $@

$(OBJ_DIR)/test.hex: $(OBJ_DIR)/test.elf
	$(OBJCOPY) -O verilog $< $@

#%.o: %.c
#	$(CC) $(CFLAGS) -c $< -o $@

#%.E: %.c
#	$(CC) $(CFLAGS) -E -c $< -o $@

#%.D: %.elf
#	$(SCRIPTS)/dissassembly.py $<

#%.D: %.o
#	$(SCRIPTS)/dissassembly.py $<

