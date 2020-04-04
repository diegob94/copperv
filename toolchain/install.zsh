#!/usr/bin/zsh

info(){
    echo INFO: $1
}

INSTALL_PATH=$0:A:h
info "Installing GCC at: $INSTALL_PATH"

info 'Installing dependencies'
sudo apt-get --yes install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

info 'Cloning riscv-gnu-toolchain repository'
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain

cd riscv-gnu-toolchain

./configure --prefix=$INSTALL_PATH
make -j$(nproc)

