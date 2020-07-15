ARG UBUNTU_VERSION=16.04

FROM ubuntu:${UBUNTU_VERSION} AS base

# ================================================================================
# dependcy package of Emacs
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            apt-utils \
            curl \
            gnupg \
            gpm \
            imagemagick \
            ispell \
            libacl1 \
            libasound2 \
            libcanberra-gtk3-module \
            libdbus-1-3 \
            libgif7 \
            libgnutls30 \
            libgtk-3-0 \
            libjansson4 \
            libjpeg8 \
            liblcms2-2 \
            libm17n-0 \
            libpng16-16 \
            librsvg2-2 \
            libsm6 \
            libtiff5 \
            libx11-xcb1 \
            libxml2 \
            libxpm4 \
            openssh-client \
            texinfo \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ================================================================================
# dependcy of caffe
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            cmake \
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
            virtualenv \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# ================================================================================

COPY ./local /usr/local

WORKDIR /workspace
