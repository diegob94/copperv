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

| Test    |        | Result   |      |
|---------|--------|----------|------|
| test_0  | Passed |          |      |
| addi    | Passed |          |      |
| add     | Passed |          |      |
| andi    | Passed |          |      |
| and     | Passed |          |      |
| auipc   | Passed |          |      |
| beq     | Passed |          |      |
| bge     | Passed |          |      |
| bgeu    | Passed |          |      |
| blt     | Passed |          |      |
| bltu    | Passed |          |      |
| bne     | Passed |          |      |
| fence_i |        | Failed   |      |
| jalr    |        | Failed   |      |
| jal     | Passed |          |      |
| lb      |        | Failed   |      |
| lbu     |        | Failed   |      |
| lh      |        | Failed   |      |
| lhu     |        | Failed   |      |
| lui     |        | Failed   |      |
| lw      |        | Failed   |      |
| ori     |        | Failed   |      |
| or      |        | Failed   |      |
| sb      |        | Failed   |      |
| sh      |        | Failed   |      |
| simple  | Passed |          |      |
| slli    |        | Failed   |      |
| sll     |        | Failed   |      |
| slti    |        | Failed   |      |
| sltiu   |        | Failed   |      |
| slt     |        | Failed   |      |
| sltu    |        | Failed   |      |
| srai    |        | Failed   |      |
| sra     |        | Failed   |      |
| srli    |        | Failed   |      |
| srl     |        | Failed   |      |
| sub     | Passed |          |      |
| sw      |        | Failed   |      |
| xori    |        | Failed   |      |
| xor     |        | Failed   |      |
| Summary | ---    | ---      | ---  |
| 40      | 15     | 25       | 0    |
| 100.0%  | 37.5%  | 62.5%    | 0.0% |

