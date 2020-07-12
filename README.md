# copperv
RISCV core

## Usage
- https://github.com/riscv/riscv-gnu-toolchain
  - Clone to ./util/riscv-gnu-toolchain
  - ./configure --prefix=$(readlink -f ./util/toolchain) --with-arch=rv32i
  - Add as submodule?
- https://github.com/riscv/riscv-tests
  - Clone to ./util/riscv-tests
  - Add as submodule?
- https://www.accellera.org/downloads/standards/ovl
  - Download to ./util/std_ovl
  - Optional?
- http://iverilog.icarus.com/
- Python 3:
  - Pyenv is recommended to install latest python
  - pip install -r requirements.txt
- Basic simulation:
  - mkdir work
  - ln -s ../scripts/Makefile work/Makefile
  - cd work
  - make
- Run unit tests:
  - cd work
  - make test_all

## To Do
- Write dissassembly monitor in C

## Unit test results:

| Test    |        | Result   |       |
|---------|--------|----------|-------|
| test_0  | Passed |          |       |
| add     | Passed |          |       |
| addi    | Passed |          |       |
| and     | Passed |          |       |
| andi    | Passed |          |       |
| auipc   | Passed |          |       |
| beq     | Passed |          |       |
| bge     | Passed |          |       |
| bgeu    | Passed |          |       |
| blt     | Passed |          |       |
| bltu    | Passed |          |       |
| bne     | Passed |          |       |
| fence_i |        | Failed   |       |
| jal     | Passed |          |       |
| jalr    | Passed |          |       |
| lb      | Passed |          |       |
| lbu     | Passed |          |       |
| lh      | Passed |          |       |
| lhu     | Passed |          |       |
| lui     | Passed |          |       |
| lw      | Passed |          |       |
| or      | Passed |          |       |
| ori     |        | Failed   |       |
| sb      |        |          | Error |
| sh      |        | Failed   |       |
| simple  | Passed |          |       |
| sll     |        | Failed   |       |
| slli    | Passed |          |       |
| slt     |        |          | Error |
| slti    |        | Failed   |       |
| sltiu   |        | Failed   |       |
| sltu    |        |          | Error |
| sra     |        | Failed   |       |
| srai    | Passed |          |       |
| srl     |        | Failed   |       |
| srli    | Passed |          |       |
| sub     | Passed |          |       |
| sw      |        | Failed   |       |
| xor     | Passed |          |       |
| xori    |        | Failed   |       |
| Summary | ---    | ---      | ---   |
| 40      | 27     | 10       | 3     |
| 100.0%  | 67.5%  | 25.0%    | 7.5%  |

