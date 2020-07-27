SHELL = bash

SDK = $(ROOT)/sdk
RISCV_TESTS = $(UTIL)/riscv-tests
LINKER_SCRIPT = $(SDK)/linker.ld
TOOLCHAIN = $(RISCV)/bin/riscv32-unknown-elf-
CC = $(TOOLCHAIN)gcc
OBJDUMP = $(TOOLCHAIN)objdump
OBJCOPY = $(TOOLCHAIN)objcopy

LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i -I$(SDK) -I$(SIM)/tests -I$(RISCV_TESTS)/isa/macros/scalar

TEST_DEPS := $(shell ../scripts/get_test.py $(TEST) $(SDK))

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

$(TEST).elf: $(TEST_DEPS) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $(filter %.o, $^) -o $@

$(TEST).hex: $(TEST).elf $(TEST).D
	$(OBJCOPY) -O verilog $< $@

%.D: %.elf
	$(SCRIPTS)/dissassembly.py $<

%.D: %.o
	$(SCRIPTS)/dissassembly.py $<

.PHONY: clean_test
clean_test:
	rm -fv *.hex *.elf
ifneq ($(ROOT),)
	find -L $(RISCV_TESTS) $(SIM) $(SDK) ./ \( -name '*.o' -o -name '*.D' -o -name '*.E' \) -exec rm -fv {} \;
endif



