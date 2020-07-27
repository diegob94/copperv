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

## Regression results:

| Test        |        | Result   |      |
|-------------|--------|----------|------|
| hello_world | Passed |          |      |
| sb_limits   | Passed |          |      |
| sh_limits   | Passed |          |      |
| test_0      | Passed |          |      |
| add         | Passed |          |      |
| addi        | Passed |          |      |
| and         | Passed |          |      |
| andi        | Passed |          |      |
| auipc       | Passed |          |      |
| beq         | Passed |          |      |
| bge         | Passed |          |      |
| bgeu        | Passed |          |      |
| blt         | Passed |          |      |
| bltu        | Passed |          |      |
| bne         | Passed |          |      |
| fence_i     | Passed |          |      |
| jal         | Passed |          |      |
| jalr        | Passed |          |      |
| lb          | Passed |          |      |
| lbu         | Passed |          |      |
| lh          | Passed |          |      |
| lhu         | Passed |          |      |
| lui         | Passed |          |      |
| lw          | Passed |          |      |
| or          | Passed |          |      |
| ori         | Passed |          |      |
| sb          | Passed |          |      |
| sh          | Passed |          |      |
| simple      | Passed |          |      |
| sll         | Passed |          |      |
| slli        | Passed |          |      |
| slt         | Passed |          |      |
| slti        | Passed |          |      |
| sltiu       | Passed |          |      |
| sltu        | Passed |          |      |
| sra         | Passed |          |      |
| srai        | Passed |          |      |
| srl         | Passed |          |      |
| srli        | Passed |          |      |
| sub         | Passed |          |      |
| sw          | Passed |          |      |
| xor         | Passed |          |      |
| xori        | Passed |          |      |
| Summary     | ---    | ---      | ---  |
| 43          | 43     | 0        | 0    |
| 100.0%      | 100.0% | 0.0%     | 0.0% |

