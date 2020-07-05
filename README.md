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
- ZSH
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
  - ../scripts/unit_test.zsh

## To Do
- Easier make UI: make TEST=test_0
- Write dissassembly monitor in C

## Unit test results:

| Test    |        | Result   |       |
|---------|--------|----------|-------|
| test_0  | Passed |          |       |
| addi    | Passed |          |       |
| add     | Passed |          |       |
| andi    | Passed |          |       |
| and     | Passed |          |       |
| auipc   |        |          | Error |
| beq     | Passed |          |       |
| bge     | Passed |          |       |
| bgeu    | Passed |          |       |
| blt     | Passed |          |       |
| bltu    | Passed |          |       |
| bne     | Passed |          |       |
| fence_i |        | Failed   |       |
| jalr    |        |          | Error |
| jal     |        |          | Error |
| lb      |        |          | Error |
| lbu     |        |          | Error |
| lh      |        |          | Error |
| lhu     |        |          | Error |
| lui     |        | Failed   |       |
| lw      |        |          | Error |
| ori     |        | Failed   |       |
| or      |        | Failed   |       |
| sb      | Passed |          |       |
| sh      | Passed |          |       |
| simple  | Passed |          |       |
| slli    |        | Failed   |       |
| sll     |        | Failed   |       |
| slti    |        | Failed   |       |
| sltiu   |        | Failed   |       |
| slt     |        | Failed   |       |
| sltu    |        | Failed   |       |
| srai    |        | Failed   |       |
| sra     |        | Failed   |       |
| srli    |        | Failed   |       |
| srl     |        | Failed   |       |
| sub     | Passed |          |       |
| sw      | Passed |          |       |
| xori    |        | Failed   |       |
| xor     |        | Failed   |       |
| Summary | ---    | ---      | ---   |
| 40      | 16     | 16       | 8     |
| 100.0%  | 40.0%  | 40.0%    | 20.0% |

