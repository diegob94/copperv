FROM ubuntu:focal-20210217 AS build_iverilog

ARG DEBIAN_FRONTEND=noninteractive 
WORKDIR /src

# Build essential
RUN apt-get update
RUN apt-get -y --no-install-recommends install build-essential git \
        ca-certificates wget software-properties-common

RUN apt-get -y --no-install-recommends install gperf autoconf flex bison
RUN git clone --progress https://github.com/steveicarus/iverilog.git
WORKDIR /src/iverilog
RUN git checkout --track -b v11-branch origin/v11-branch
RUN sh autoconf.sh
RUN ./configure --prefix=/eda/iverilog
RUN make -j$(nproc)
RUN make install

FROM ubuntu:focal-20210217

ENV PATH="/eda/iverilog/bin:${PATH}"
WORKDIR /container

COPY --from=build_iverilog /eda/iverilog /eda/iverilog

