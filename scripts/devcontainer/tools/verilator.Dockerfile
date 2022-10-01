FROM ubuntu:focal-20210217 AS build_verilator

ARG DEBIAN_FRONTEND=noninteractive 
WORKDIR /src

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
                        autoconf \
                        bc \
                        bison \
                        build-essential \
                        ca-certificates \
                        ccache \
                        flex \
                        git \
                        libfl-dev \
                        libgoogle-perftools-dev \
                        perl \
                        python3

RUN git clone --progress https://github.com/verilator/verilator verilator
WORKDIR verilator
ARG TAG=v4.200
RUN git checkout "${TAG}" -b branch-"${TAG}"

RUN autoconf
RUN ./configure --prefix=/eda/verilator
RUN make -j "$(nproc)"
RUN make install

FROM ubuntu:focal-20210217

ARG DEBIAN_FRONTEND=noninteractive 
WORKDIR /work

ENV PATH="/eda/verilator/bin:${PATH}"
COPY --from=build_verilator /eda/verilator /eda/verilator

RUN apt-get update \
    && apt-get install --no-install-recommends -y cmake make gcc g++ gdb perl ccache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

