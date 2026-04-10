FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    flex \
    bison \
    g++ \
    gdb \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
