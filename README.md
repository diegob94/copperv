# copperv
RISCV core

## Usage
- Install RISCV GCC and export RISCV env variable like: $RISCV/bin/riscv32-unknown-elf-gcc
  - ./configure --prefix=$RISCV --with-arch=rv32i
- Dependencies:
  - Icarus Verilog
  - Verilator
  - Yosys
  - GTKWave
  - Python 3.8
    - pip install -r requirements.txt
- Run simulation:
  - mkdir work
  - ln -s ../scripts/Makefile work/Makefile
  - cd work
  - make
- Run regression tests:
  - cd work
  - make test_all
- Hello World:
  - cd work
  - make TEST=hello_world
  - cat fake_uart.txt

## To Do
- take_branch X?

