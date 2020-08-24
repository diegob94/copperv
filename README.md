# copperv
RISCV core

## Usage
- Install environment:
  - conda env create -f environment.yml
- Run simulation:
  - mkdir work
  - ln -s ../scripts/Makefile work/Makefile
  - cd work
  - make
- Run regression tests:
  - cd work
  - make test
- Hello World:
  - cd work
  - make TEST=hello_world
  - cat fake_uart.txt

## To Do
- take_branch X?

