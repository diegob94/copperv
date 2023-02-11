
TEST ?= hello_world
TEST_DIR = ../tests/$(TEST)
TEST_BIN = $(TEST_DIR)/$(TEST).bin
EXEC = copperv_sim

.PHONY: all
all: $(EXEC) $(TEST_BIN)
	./$(EXEC) $(TEST_BIN)

$(EXEC): copperv_sim.c

$(TEST_BIN):
	$(MAKE) -C $(TEST_DIR) $(notdir $(TEST_BIN))

.PHONY: clean
clean:
	rm -vf $(EXEC)

