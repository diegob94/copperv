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
| ori     | Passed |          |       |
| sb      |        |          | Error |
| sh      |        | Failed   |       |
| simple  | Passed |          |       |
| sll     | Passed |          |       |
| slli    | Passed |          |       |
| slt     |        |          | Error |
| slti    |        |          | Error |
| sltiu   |        |          | Error |
| sltu    |        |          | Error |
| sra     | Passed |          |       |
| srai    | Passed |          |       |
| srl     | Passed |          |       |
| srli    | Passed |          |       |
| sub     | Passed |          |       |
| sw      |        | Failed   |       |
| xor     | Passed |          |       |
| xori    | Passed |          |       |
| Summary | ---    | ---      | ---   |
| 40      | 32     | 3        | 5     |
| 100.0%  | 80.0%  | 7.5%     | 12.5% |

