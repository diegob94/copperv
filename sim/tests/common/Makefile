
COMMON_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
ROOT_DIR := $(realpath $(COMMON_DIR)/../../..)
SCRIPTS_DIR := $(ROOT_DIR)/scripts

LINKER_SCRIPT ?= $(COMMON_DIR)/linker.ld
CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
override CFLAGS += -march=rv32i -mabi=ilp32 -I$(COMMON_DIR)
LDFLAGS += -march=rv32i -mabi=ilp32
BOOTLOADER =
BOOTLOADER_OBJ = $(BOOTLOADER:.S=.o)
INIT_OBJ = crt0.o syscalls.o $(BOOTLOADER_OBJ)
ifdef NO_INIT
INIT_OBJ = 
endif
ifdef NO_SYSCALLS
INIT_OBJ = crt0.o $(BOOTLOADER_OBJ)
endif
ifeq ($(BOOTLOADER),)
override CFLAGS += -DNO_BOOTLOADER
endif

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
	$(CC) $(CFLAGS) -E $< -o $(@:.o=.E)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
	$(CC) $(CFLAGS) -E $< -o $(@:.o=.E)

%.o: $(COMMON_DIR)/%.S
	$(CC) $(CFLAGS) -c $< -o $@
	$(CC) $(CFLAGS) -E $< -o $(@:.o=.E)

%.o: $(COMMON_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@
	$(CC) $(CFLAGS) -E $< -o $(@:.o=.E)

%.elf: %.o $(INIT_OBJ)
	$(CC) $(LDFLAGS) -Wl,-T,$(LINKER_SCRIPT),-Bstatic -nostartfiles -ffreestanding $^ -o $@
	$(SCRIPTS_DIR)/utils.py debug $@ || true

%.hex: %.elf
	$(OBJCOPY) -O verilog $< $@

.PHONY: clean
clean:
	rm -fv *.o *.elf *.debug *.E *.hex
