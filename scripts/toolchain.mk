SHELL = bash -o pipefail
INFO = @echo "`tput setaf 2``tput bold`toolchain-make:`tput init`"

LINKER_SCRIPT = $(SDK)/linker.ld
ifeq ($(STARTUP_ROUTINE),)
override STARTUP_ROUTINE = $(SDK)/crt0.S
endif
TOOLCHAIN = riscv64-unknown-elf-
CC      = $(TOOLCHAIN)gcc
OBJDUMP = $(TOOLCHAIN)objdump
OBJCOPY = $(TOOLCHAIN)objcopy

SCRIPTS = $(ROOT)/scripts

LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
override CFLAGS += -march=rv32i -mabi=ilp32 -I$(SDK)

BIN_NAME := $(shell basename $(SRC_DIR))
SRC_FILES_ASM = $(STARTUP_ROUTINE)
SRC_FILES_ASM += $(wildcard $(SRC_DIR)/*.S)
SRC_FILES_C += $(wildcard $(SRC_DIR)/*.c)
SRC_FILES = $(SRC_FILES_ASM)
SRC_FILES += $(SRC_FILES_C)
SRC_FILES_ASM_NAMES = $(notdir $(SRC_FILES_ASM))
SRC_FILES_C_NAMES = $(notdir $(SRC_FILES_C))

OBJ_FILES = $(addprefix $(OBJ_DIR)/,$(SRC_FILES_ASM_NAMES:.S=.o))
OBJ_FILES += $(addprefix $(OBJ_DIR)/,$(SRC_FILES_C_NAMES:.c=.o))
PREPROC_FILES = $(addprefix $(OBJ_DIR)/,$(SRC_FILES_ASM_NAMES:.S=.E))
PREPROC_FILES += $(addprefix $(OBJ_DIR)/,$(SRC_FILES_C_NAMES:.c=.E))

DEBUG = 0

.SUFFIXES:
.PHONY: all
all: $(OBJ_DIR)/$(BIN_NAME).hex

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S
ifneq ($(DEBUG),0)
	$(INFO) Compiling ASM obj $@
endif
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
ifneq ($(DEBUG),0)
	$(INFO) Compiling C obj $@
endif
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(STARTUP_ROUTINE)
ifneq ($(DEBUG),0)
	$(INFO) Compiling STARTUP_ROUTINE obj $@
endif
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.E: $(SRC_DIR)/%.S
	$(CC) $(CFLAGS) -E -c $< -o $@
	grep -Ev '^#|^$$' $@ | tr ';' '\n' > $@1

$(OBJ_DIR)/%.E: $(STARTUP_ROUTINE)
	$(CC) $(CFLAGS) -E -c $< -o $@
	grep -Ev '^#|^$$' $@ | tr ';' '\n' > $@1

$(OBJ_DIR)/%.E: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -E -c $< -o $@

$(OBJ_DIR)/$(BIN_NAME).elf: $(OBJ_FILES) $(PREPROC_FILES) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $(OBJ_FILES) -o $@

## Simulation inputs
$(OBJ_DIR)/$(BIN_NAME).hex: $(OBJ_DIR)/$(BIN_NAME).elf $(OBJ_DIR)/$(BIN_NAME).D
ifneq ($(DEBUG),0)
	@echo "Source files:"
	@echo $(SRC_FILES) | xargs | tr ' ' '\n' | sed 's/^/  - /'
	@echo
	@echo "Object files:"
	@echo $(OBJ_FILES) | xargs | tr ' ' '\n' | sed 's/^/  - /'
	@echo
	@echo "Startup_routine:"
	@echo '  - $(STARTUP_ROUTINE)'
endif
	$(OBJCOPY) -O verilog $< $@

$(OBJ_DIR)/$(BIN_NAME).D: $(OBJ_DIR)/$(BIN_NAME).elf
	$(SCRIPTS)/dissassembly.py $<


