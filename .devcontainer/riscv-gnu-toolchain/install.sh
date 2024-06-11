#!/bin/bash

RISCV=/usr/local/riscv

apt-get update
apt-get install -y autoconf automake autotools-dev curl \
    python3 python3-pip libmpc-dev libmpfr-dev libgmp-dev \
    gawk build-essential bison flex texinfo gperf libtool \
    patchutils bc zlib1g-dev libexpat-dev ninja-build git \
    cmake libglib2.0-dev libslirp-dev
rm -rf /var/lib/apt/lists/*

git clone https://github.com/riscv/riscv-gnu-toolchain

cd riscv-gnu-toolchain

./configure --enable-multilib --prefix $RISCV
make -j4

