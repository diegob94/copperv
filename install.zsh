#!/usr/bin/zsh

info(){
    echo INFO: $@
}
create_dir(){
    DIR=($1)
    if [[ ! -d $DIR ]]; then
        mkdir $DIR
        info Creating directory ${DIR:a}
    else
        info ${DIR:a} already exists
    fi
}
install_deps(){
    DEPS=("$@")
    for DEP in $DEPS; do
        if dpkg -s $DEP | grep 'Status.*installed' -q; then
            info $DEP already installed
        else
            info Installing dependencie $DEP
            sudo apt-get --yes install $DEP 
        fi
    done
}

ROOT=${0:a:h}/toolchain
create_dir $ROOT
pushd $ROOT

INSTALL_PATH=$ROOT
TEMP_DIR=tmp

info "Installing toolchain at: $INSTALL_PATH"

create_dir $INSTALL_PATH
create_dir $TEMP_DIR

DEPS=(autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat1-dev)
install_deps $DEPS

pushd $TEMP_DIR

if [[ ! -d riscv-gnu-toolchain ]]; then
    info 'Cloning riscv-gnu-toolchain repository'
    git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
else
    info 'riscv-gnu-toolchain already exists'
fi

pushd riscv-gnu-toolchain

./configure --prefix=$INSTALL_PATH --with-arch=rv32i
make -j$(nproc)

