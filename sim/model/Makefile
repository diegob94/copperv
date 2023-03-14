
TEST ?= hello_world
TEST_DIR = ../tests/$(TEST)
TEST_BIN = $(TEST_DIR)/$(TEST).bin
EXEC = copperv_sim

ifdef DEBUG
GDB = gdb --args
CFLAGS = -g
debug_clean: clean all
endif

.PHONY: all
all: $(EXEC) $(TEST_BIN)
	$(GDB) ./$(EXEC) $(TEST_BIN)

$(EXEC): copperv_sim.c idecode.c copperv_sim.h
	$(CC) $(CFLAGS) copperv_sim.c idecode.c -o $@

$(TEST_BIN):
	$(MAKE) -C $(TEST_DIR) $(notdir $(TEST_BIN))

.PHONY: clean
clean:
	rm -vf $(EXEC)

