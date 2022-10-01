FROM ubuntu:focal-20210217

ARG DEBIAN_FRONTEND=noninteractive 

# iverilog
ENV PATH="/eda/iverilog/bin:${PATH}"
COPY --from=diegob94/open_eda:iverilog /eda/iverilog /eda/iverilog

# riscv
ENV PATH="/eda/riscv-gnu-toolchain/bin:${PATH}"
COPY --from=diegob94/open_eda:riscv /eda/riscv-gnu-toolchain /eda/riscv-gnu-toolchain

# chisel
RUN apt-get update \
    && apt-get install --no-install-recommends -y default-jdk gnupg2 \
    && echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 \
    && apt-get update \
    && apt-get install --no-install-recommends -y sbt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# cocotb deps
RUN apt-get update \
    && apt-get install --no-install-recommends -y python3 python3-pip python3-dev \
    && apt-get install --no-install-recommends -y cmake make gcc g++ gdb perl ccache \
    && ln -s /usr/bin/pip3 /usr/bin/pip \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# cocotb
RUN pip install --no-cache-dir cocotb cocotb-coverage pytest remote_pdb pyelftools flake8 debugpy

# dev
RUN apt-get update \
    && apt-get install --no-install-recommends -y git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /container
