.PHONY: all
all: run

test.so: test.c
	$(CC) -shared -fPIC -o $@ $^

obj_dir/Vtest: test.sv test.so
	verilator --binary -Wno-fatal test.sv $(abspath test.so) 2>&1 | tee verilator.log

.PHONY: run
run: obj_dir/Vtest
	obj_dir/Vtest

.PHONY: clean
clean:
	rm -rfv test.so obj_dir verilator.log
