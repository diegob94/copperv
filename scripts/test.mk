SHELL = bash

RISCV_TESTS = $(UTIL)/riscv-tests
LINKER_SCRIPT = $(SIM)/tests/test.ld
TOOLCHAIN = $(RISCV)/bin/riscv32-unknown-elf-
CC = $(TOOLCHAIN)gcc
OBJDUMP = $(TOOLCHAIN)objdump

LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i -I$(SIM)/tests -I$(RISCV_TESTS)/isa/macros/scalar

TEST_SOURCES = $(shell ../scripts/get_test.py $(TEST))
OBJS = $(TEST_SOURCES:.S=.o)
PPRC = $(TEST_SOURCES:.S=.E)
DISS = $(TEST_SOURCES:.S=.D)

define DISSASSEMBLY
$(OBJDUMP) -D -Mno-aliases $< -j .text > $@
-$(OBJDUMP) -s $< -j .data >> $@
endef

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
#	$(TOOLCHAIN)objcopy -O elf32-littleriscv -R .riscv.attributes $@

%.E: %.S
	$(CC) $(CFLAGS) -E -c $< -o $@
	grep -Pv '^#|^$$' $@ | tr ';' '\n' > $(notdir $@)

$(TEST).elf: $(OBJS) $(DISS) $(PPRC) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $< -o $@

$(TEST).hex: $(TEST).elf $(SIM)/include/monitor_utils_h.v $(TEST).D
	$(TOOLCHAIN)objcopy -O verilog $< $@

%.D: %.elf
	$(DISSASSEMBLY)

%.D: %.o
	$(DISSASSEMBLY)

$(TEST).hex_dump: $(TEST).hex
	$(SCRIPTS)/hex_dump.py $< -o $@

$(SIM)/include/monitor_utils_h.v: $(RTL)/include/copperv_h.v $(TEST).D $(SCRIPTS)/monitor_utils.py
	$(SCRIPTS)/monitor_utils.py -monitor $@ $(RTL)/include/copperv_h.v $(TEST).D

.PHONY: clean_test
clean_test:
	rm -fv *.hex *.elf *.hex_dump run_test_*.log 
ifneq ($(ROOT),)
	find $(RISCV_TESTS) $(SIM) ./ \( -name '*.o' -o -name '*.D' -o -name '*.E' \) -exec rm -fv {} \;
endif



