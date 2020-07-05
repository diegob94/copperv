# copperv
RISCV core

## Usage
- https://github.com/riscv/riscv-gnu-toolchain
  -  Clone to $ROOT/util/riscv-gnu-toolchain  
  -  Set install prefix $ROOT/util/toolchain
- https://github.com/riscv/riscv-tests
  -  Clone to $ROOT/util/riscv-tests
- https://www.accellera.org/downloads/standards/ovl
  -  Download to $ROOT/util/std_ovl
- http://iverilog.icarus.com/
- ZSH
- Python 3:
  - Recommended to use pyenv to install last python
  - pip install -r requirements.txt
- Basic simulation:
  - mkdir work
  - ln -s ../scripts/Makefile work/Makefile
  - cd work
  - make
- Unit tests:
  - cd work
  - ../scripts/unit_test.zsh

## Unit test results:

| Test    |        | Result   |       |
|---------|--------|----------|-------|
| test_0  | Passed |          |       |
| addi    | Passed |          |       |
| add     | Passed |          |       |
| andi    |        | Failed   |       |
| and     |        | Failed   |       |
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
| 40      | 14     | 18       | 8     |
| 100.0%  | 35.0%  | 45.0%    | 20.0% |

