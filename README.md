# copperv
RISCV core

## Usage
- Install toolchain
  - riscv-gnu-toolchain git:(master) ./configure --prefix $(readlink -f ~/cad/riscv/toolchain_multilib) --enable-multilib
  - riscv-gnu-toolchain git:(master) make -j$(nproc)

## TODO build tool
- Fix linker missing flags

