ARG UBUNTU_VERSION=16.04

FROM ubuntu:${UBUNTU_VERSION} AS builder

# ================================================================================
# dependency of caffe
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            git \
            wget \
            libatlas-base-dev \
            libboost-all-dev \
            libgflags-dev \
            libgoogle-glog-dev \
            libhdf5-serial-dev \
            libleveldb-dev \
            liblmdb-dev \
            libopencv-dev \
            libprotobuf-dev \
            libsnappy-dev \
            protobuf-compiler \
            python3-dev \
            python3-numpy \
            python3-pip \
            python3-setuptools \
            python3-scipy \
            # dev needed
            virtualenv \
            parallel \
            gdb \
            unzip \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# ================================================================================

RUN python3 -m pip --no-cache-dir install --upgrade \
    pip \
    setuptools \
    # umodel dependency
    prefect \
    asciidag \
    GitPython \
    # ufw dependency
    Cython \
    numpy \
    scipy \
    leveldb \
    nose \
    pandas \
    python-dateutil \
    protobuf \
    python-gflags \
    six \
    plotly \
    tqdm \
    jupyter \
    opencv-python \
    lmdb

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV SHELL "/bin/bash"
