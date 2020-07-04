SHELL = /usr/bin/zsh

RISCV_TESTS = $(UTIL)/riscv-tests
LINKER_SCRIPT = $(SIM)/tests/test.ld
TOOLCHAIN = $(UTIL)/toolchain/bin/riscv32-unknown-elf-
CC = $(TOOLCHAIN)gcc

LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i -I$(SIM)/tests -I$(RISCV_TESTS)/isa/macros/scalar

TEST_SOURCES = $(SIM)/tests/test_0.S
#TEST_SOURCES = $(RISCV_TESTS)/isa/rv32ui/simple.S
OBJS = $(TEST_SOURCES:.S=.o)
DISS = $(TEST_SOURCES:.S=.D)

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
	$(CC) $(CFLAGS) -E -c $< -o $(@:.o=.E)
	$(TOOLCHAIN)objcopy -O elf32-littleriscv -R .riscv.attributes $@

$(TEST_NAME).elf: $(OBJS) $(DISS) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $< -o $@

$(TEST_NAME).hex: $(TEST_NAME).elf $(SIM)/include/monitor_utils_h.v $(TEST_NAME).D
	$(TOOLCHAIN)objcopy -O verilog $< $@

$(TEST_NAME).D: $(TEST_NAME).elf
	$(TOOLCHAIN)objdump -D -Mno-aliases $< > $@

%.D: %.o
	$(TOOLCHAIN)objdump -D -Mno-aliases $< > $@

$(TEST_NAME).hex_dump: $(TEST_NAME).hex
	$(SCRIPTS)/hex_dump.py $< -o $@

$(SIM)/include/monitor_utils_h.v: $(RTL)/include/copperv_h.v $(TEST_NAME).D $(SCRIPTS)/monitor_utils.py
	$(SCRIPTS)/monitor_utils.py -monitor $@ $(RTL)/include/copperv_h.v $(TEST_NAME).D

.PHONY: clean_test
clean_test:
	setopt NULL_GLOB; rm -fv *.D *.hex *.elf *.hex_dump 
	setopt NULL_GLOB; rm -fv $(SIM)/**/*.o $(SIM)/**/*.D $(SIM)/**/*.E
	setopt NULL_GLOB; rm -fv $(RISCV_TESTS)/**/*.o $(RISCV_TESTS)/**/*.D $(RISCV_TESTS)/**/*.E

