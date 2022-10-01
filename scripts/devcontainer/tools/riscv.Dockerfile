FROM ubuntu:focal-20210217 AS build_riscv_toolchain

ARG DEBIAN_FRONTEND=noninteractive 
WORKDIR /src

# Build essential
RUN apt-get update \
    && apt-get -y --no-install-recommends install build-essential git \
        ca-certificates wget software-properties-common

RUN apt-get update
RUN apt-get -y --no-install-recommends install autoconf automake autotools-dev curl python3 \
        libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex \ 
        texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
WORKDIR /src/riscv-gnu-toolchain
RUN git checkout tags/2021.03.26 -b 2021.03.26-branch
RUN ./configure --prefix=/eda/riscv-gnu-toolchain --enable-multilib
RUN make -j$(nproc)
WORKDIR /eda/riscv-gnu-toolchain
RUN    strip --strip-unneeded libexec/gcc/riscv64-unknown-elf/10.2.0/cc1plus \
    && strip --strip-unneeded libexec/gcc/riscv64-unknown-elf/10.2.0/cc1 \
    && strip --strip-unneeded libexec/gcc/riscv64-unknown-elf/10.2.0/lto1 \
    && strip --strip-unneeded bin/riscv64-unknown-elf-addr2line \
    && strip --strip-unneeded bin/riscv64-unknown-elf-ar \
    && strip --strip-unneeded bin/riscv64-unknown-elf-as \
    && strip --strip-unneeded bin/riscv64-unknown-elf-c++ \
    && strip --strip-unneeded bin/riscv64-unknown-elf-c++filt \
    && strip --strip-unneeded bin/riscv64-unknown-elf-cpp \
    && strip --strip-unneeded bin/riscv64-unknown-elf-elfedit \
    && strip --strip-unneeded bin/riscv64-unknown-elf-g++ \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gcc \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gcc-10.2.0 \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gcc-ar \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gcc-nm \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gcc-ranlib \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gcov \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gcov-dump \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gcov-tool \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gdb \
    && strip --strip-unneeded bin/riscv64-unknown-elf-gprof \
    && strip --strip-unneeded bin/riscv64-unknown-elf-ld \
    && strip --strip-unneeded bin/riscv64-unknown-elf-ld.bfd \
    && strip --strip-unneeded bin/riscv64-unknown-elf-lto-dump \
    && strip --strip-unneeded bin/riscv64-unknown-elf-nm \
    && strip --strip-unneeded bin/riscv64-unknown-elf-objcopy \
    && strip --strip-unneeded bin/riscv64-unknown-elf-objdump \
    && strip --strip-unneeded bin/riscv64-unknown-elf-ranlib \
    && strip --strip-unneeded bin/riscv64-unknown-elf-readelf \
    && strip --strip-unneeded bin/riscv64-unknown-elf-run \
    && strip --strip-unneeded bin/riscv64-unknown-elf-size \
    && strip --strip-unneeded bin/riscv64-unknown-elf-strings \
    && strip --strip-unneeded bin/riscv64-unknown-elf-strip \
    && strip --strip-unneeded riscv64-unknown-elf/bin/ar \
    && strip --strip-unneeded riscv64-unknown-elf/bin/as \
    && strip --strip-unneeded riscv64-unknown-elf/bin/ld \
    && strip --strip-unneeded riscv64-unknown-elf/bin/ld.bfd \
    && strip --strip-unneeded riscv64-unknown-elf/bin/nm \
    && strip --strip-unneeded riscv64-unknown-elf/bin/objcopy \
    && strip --strip-unneeded riscv64-unknown-elf/bin/objdump \
    && strip --strip-unneeded riscv64-unknown-elf/bin/ranlib \
    && strip --strip-unneeded riscv64-unknown-elf/bin/readelf \
    && strip --strip-unneeded riscv64-unknown-elf/bin/strip

FROM ubuntu:focal-20210217

ENV PATH="/eda/riscv-gnu-toolchain/bin:${PATH}"

COPY --from=build_riscv_toolchain /eda/riscv-gnu-toolchain /eda/riscv-gnu-toolchain

