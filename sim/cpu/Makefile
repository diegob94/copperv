export OBJCACHE = ccache

WA = -CFLAGS "-I$(CONDA_PREFIX)/include"

.PHONY: all
all: testbench.fst

.PHONY: verilate
verilate:
	verilator -F copperv_tb.files --binary --top testbench --trace-fst $(WA)

testbench.fst: verilate
	./obj_dir/Vtestbench
	mv testbench.vcd testbench.fst

.PHONY: clean clean_all
clean:
	rm -rfv obj_dir
	rm -fv *.fst *.vcd

clean_all: clean
	rm -fv *.gtkw
