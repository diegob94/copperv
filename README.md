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
| addi    |        | Failed   |       |
| add     | Passed |          |       |
| andi    | Passed |          |       |
| and     |        | Failed   |       |
| auipc   |        |          | Error |
| beq     | Passed |          |       |
| bge     | Passed |          |       |
| bgeu    | Passed |          |       |
| blt     | Passed |          |       |
| bltu    | Passed |          |       |
| bne     | Passed |          |       |
| fence_i | Passed |          |       |
| jalr    |        |          | Error |
| jal     |        |          | Error |
| lb      |        |          | Error |
| lbu     |        |          | Error |
| lh      |        |          | Error |
| lhu     |        |          | Error |
| lui     | Passed |          |       |
| lw      |        |          | Error |
| ori     | Passed |          |       |
| or      |        | Failed   |       |
| sb      |        | Failed   |       |
| sh      |        | Failed   |       |
| simple  | Passed |          |       |
| slli    | Passed |          |       |
| sll     |        | Failed   |       |
| slti    |        | Failed   |       |
| sltiu   |        | Failed   |       |
| slt     |        | Failed   |       |
| sltu    |        | Failed   |       |
| srai    | Passed |          |       |
| sra     |        | Failed   |       |
| srli    |        | Failed   |       |
| srl     |        | Failed   |       |
| sub     | Passed |          |       |
| sw      | Passed |          |       |
| xori    | Passed |          |       |
| xor     |        | Failed   |       |
| Summary | ---    | ---      | ---   |
| 40      | 18     | 14       | 8     |
| 100.0%  | 45.0%  | 35.0%    | 20.0% |

