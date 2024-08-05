.PHONY: all
all:
	verilator ../../rtl/cpu/copperv_pkg.sv ../../rtl/bus/wishbone_if.sv ../../rtl/cpu/control_unit.v ../../rtl/cpu/copperv.sv ../../rtl/cpu/execution.v ../../rtl/cpu/idecoder.v ../../rtl/cpu/register_file.v testbench.sv --binary --top testbench -Wno-fatal
