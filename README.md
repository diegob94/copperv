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
| add     |        | Failed   |       |
| andi    |        |          | Error |
| and     |        |          | Error |
| auipc   |        |          | Error |
| beq     |        |          | Error |
| bge     |        |          | Error |
| bgeu    |        |          | Error |
| blt     |        |          | Error |
| bltu    |        |          | Error |
| bne     |        |          | Error |
| fence_i |        |          | Error |
| jalr    |        |          | Error |
| jal     |        |          | Error |
| lb      |        |          | Error |
| lbu     |        |          | Error |
| lh      |        |          | Error |
| lhu     |        |          | Error |
| lui     | Passed |          |       |
| lw      |        |          | Error |
| ori     |        |          | Error |
| or      |        |          | Error |
| sb      |        |          | Error |
| sh      |        |          | Error |
| simple  | Passed |          |       |
| slli    | Passed |          |       |
| sll     |        | Failed   |       |
| slti    | Passed |          |       |
| sltiu   | Passed |          |       |
| slt     |        | Failed   |       |
| sltu    |        | Failed   |       |
| srai    |        |          | Error |
| sra     |        | Failed   |       |
| srli    | Passed |          |       |
| srl     |        | Failed   |       |
| sub     |        | Failed   |       |
| sw      |        |          | Error |
| xori    |        |          | Error |
| xor     |        |          | Error |
| Summary | ---    | ---      | ---   |
| 40      | 8      | 7        | 25    |
| 100.0%  | 20.0%  | 17.5%    | 62.5% |

