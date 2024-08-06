export OBJCACHE = ccache

RTL_SOURCES = ../../rtl/cpu/copperv_pkg.sv
RTL_SOURCES += ../../rtl/bus/wishbone_if.sv
RTL_SOURCES += ../../rtl/cpu/control_unit.sv
RTL_SOURCES += ../../rtl/cpu/copperv.sv
RTL_SOURCES += ../../rtl/cpu/execution.v
RTL_SOURCES += ../../rtl/cpu/idecoder.sv
RTL_SOURCES += ../../rtl/cpu/register_file.v

SIM_SOURCES = ../bus/wishbone_bfm.sv testbench.sv

WA = -CFLAGS "-I$(CONDA_PREFIX)/include"

.PHONY: all
all: testbench.fst

./obj_dir/Vtestbench: $(RTL_SOURCES) $(SIM_SOURCES)
	verilator $(RTL_SOURCES) $(SIM_SOURCES) --binary --top testbench --trace-fst -Wno-fatal $(WA)

testbench.fst: ./obj_dir/Vtestbench
	./obj_dir/Vtestbench
	mv testbench.vcd testbench.fst
