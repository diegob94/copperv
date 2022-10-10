SHELL=bash

.PHONY: all
all: uart_tx.log
	@echo SUMMARY:
	@grep -H DONE $^

uart_tx.log: uart_tx.v ../rtl/uart/wb2uart.v
	sby -f $(SBY_OPTS) uart_tx.sby |& tee $@

.PHONY: clean
clean:
	rm -rf *.log *_bmc *_prove *_cover
