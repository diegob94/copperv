
TEST ?= hello_world
TESTS_DIR = tests
TEST_DIR = $(TESTS_DIR)/$(TEST)
TEST_BIN = $(TEST_DIR)/$(TEST).bin
EXEC = copperv_sim

ifdef DEBUG
CFLAGS = -g
debug_clean: clean all
endif

.PHONY: all
all: $(EXEC) $(TEST_BIN)
	stdbuf -i0 -o0 -e0 ./$(EXEC) $(TEST_BIN) | tee sim.log

$(EXEC): copperv_sim.c idecode.c copperv_sim.h
	$(CC) $(CFLAGS) copperv_sim.c idecode.c -o $@

.PHONY: $(TEST_BIN)
$(TEST_BIN):
	$(MAKE) -C $(TEST_DIR) $(notdir $(TEST_BIN))

.PHONY: clean
clean:
	rm -vf $(EXEC)

