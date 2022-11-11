
COMMON_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
ROOT_DIR := $(realpath $(COMMON_DIR)/../../..)
SCRIPTS_DIR := $(ROOT_DIR)/scripts

LINKER_SCRIPT ?= $(COMMON_DIR)/linker.ld
CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
override CFLAGS += -march=rv32i -mabi=ilp32 -I$(COMMON_DIR)
LDFLAGS += -march=rv32i -mabi=ilp32
INIT_OBJ = crt0.o syscalls.o
ifdef NO_INIT
INIT_OBJ = 
endif
ifdef NO_SYSCALLS
INIT_OBJ = crt0.o
endif
ifdef BOOTLOADER
INIT_OBJ += bootloader.o
else
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

%.elf: %.o $(INIT_OBJ) $(LINKER_SCRIPT)
	$(CC) $(LDFLAGS) -Wl,-T,$(LINKER_SCRIPT),-Bstatic -nostartfiles -ffreestanding $(filter %.o,$^) -o $@
	$(SCRIPTS_DIR)/utils.py debug $@ || true

%.hex: %.elf
	$(OBJCOPY) -O verilog $< $@

.PHONY: clean
clean:
	rm -fv *.o *.elf *.debug *.E *.hex
