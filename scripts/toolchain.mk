SHELL = bash -o pipefail

LINKER_SCRIPT = $(SDK)/linker.ld
STARTUP_ROUTINE = $(SDK)/crt0.S
TOOLCHAIN = riscv64-unknown-elf-
CC      = $(TOOLCHAIN)gcc
OBJDUMP = $(TOOLCHAIN)objdump
OBJCOPY = $(TOOLCHAIN)objcopy

SCRIPTS = $(ROOT)/scripts

LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
override CFLAGS += -march=rv32i -mabi=ilp32 -I$(SDK)

BIN_NAME = $(shell basename $(SRC_DIR))
SRC_FILES = $(STARTUP_ROUTINE)
SRC_FILES += $(wildcard $(SRC_DIR)/*.S)
SRC_FILES_NOT_DIR = $(notdir $(SRC_FILES))

OBJ_FILES = $(addprefix $(OBJ_DIR)/,$(SRC_FILES_NOT_DIR:.S=.o))
PREPROC_FILES = $(addprefix $(OBJ_DIR)/,$(SRC_FILES_NOT_DIR:.S=.E))

.SUFFIXES:
.PHONY: all banner

all: banner $(OBJ_DIR)/$(BIN_NAME).hex
	@echo
	@echo '----------------------------------------------------------------------------'
	@echo
	@echo "Copperv cross compile done: $(OBJ_DIR)"
	@echo
	@echo '----------------------------------------------------------------------------'

banner:
	@echo '----------------------------------------------------------------------------'
	@echo
	@echo "Copperv cross compile: $(OBJ_DIR)"
ifdef $(DEBUG)
	@echo "Source files:"
	@echo $(SRC_FILES) | xargs | tr ' ' '\n' | sed 's/^/  - /'
	@echo
	@echo "Object files:"
	@echo $(OBJ_FILES) | xargs | tr ' ' '\n' | sed 's/^/  - /'
endif
	@echo
	@echo '----------------------------------------------------------------------------'
	@echo

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(STARTUP_ROUTINE)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.E: $(SRC_DIR)/%.S
	$(CC) $(CFLAGS) -E -c $< -o $@
	grep -Ev '^#|^$$' $@ | tr ';' '\n' > $@1

$(OBJ_DIR)/%.E: $(SDK)/%.S
	$(CC) $(CFLAGS) -E -c $< -o $@
	grep -Ev '^#|^$$' $@ | tr ';' '\n' > $@1

$(OBJ_DIR)/$(BIN_NAME).elf: $(OBJ_FILES) $(PREPROC_FILES) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $(OBJ_FILES) -o $@

## Simulation inputs
$(OBJ_DIR)/$(BIN_NAME).hex: $(OBJ_DIR)/$(BIN_NAME).elf $(OBJ_DIR)/$(BIN_NAME).D
	$(OBJCOPY) -O verilog $< $@

$(OBJ_DIR)/$(BIN_NAME).D: $(OBJ_DIR)/$(BIN_NAME).elf
	$(SCRIPTS)/dissassembly.py $<

## Note: STARTUP_ROUTINE is needed for C only
#%.o: %.c
#	$(CC) $(CFLAGS) -c $< -o $@

#%.E: %.c
#	$(CC) $(CFLAGS) -E -c $< -o $@

