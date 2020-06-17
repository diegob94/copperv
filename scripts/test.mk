RISCV_TEST = $(UTIL)/riscv-tests
LINKER_SCRIPT = $(SIM)/tests/test.ld
TOOLCHAIN = $(UTIL)/toolchain/bin/riscv32-unknown-elf-
CC = $(TOOLCHAIN)gcc

LFLAGS = -Wl,-T,$(LINKER_SCRIPT),--strip-debug,-Bstatic -nostdlib -ffreestanding  
CFLAGS = -march=rv32i -I. -I$(RISCV_TEST)/isa/macros/scalar

FW_SOURCES = $(SIM)/tests/test_0.S
#FW_SOURCES = $(RISCV_TEST)/isa/rv32ui/simple.S
OBJS = $(FW_SOURCES:.S=.o)
DISS = $(FW_SOURCES:.S=.D)

.PHONY: test
test: $(SIM)/include/monitor_utils_h.v fw.hex fw.D fw.hex_dump

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
	$(TOOLCHAIN)objcopy -O elf32-littleriscv -R .riscv.attributes $@

fw.elf: $(OBJS) $(DISS) $(LINKER_SCRIPT)
	$(CC) $(LFLAGS) $< -o $@

fw.hex: fw.elf 
	$(TOOLCHAIN)objcopy -O verilog $< $@

fw.D: fw.elf
	$(TOOLCHAIN)objdump -D -Mno-aliases $< > $@

%.D: %.o
	$(TOOLCHAIN)objdump -D -Mno-aliases $< > $@

fw.hex_dump: fw.hex
	$(SCRIPTS)/hex_dump.py $< -o $@

$(SIM)/include/monitor_utils_h.v: $(RTL)/include/copperv_h.v fw.D $(SCRIPTS)/monitor_utils.py
	$(SCRIPTS)/monitor_utils.py -monitor $@ $(RTL)/include/copperv_h.v fw.D

.PHONY: clean_test
clean_test:
	rm -fv *.D *.hex *.elf *.hex_dump $(OBJS) $(DISS)

