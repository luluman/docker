ARG UBUNTU_VERSION=16.04

# ********************************************************************************
#
# satge 0
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            apt-utils \
            autoconf \
            automake \
            autotools-dev \
            build-essential \
            curl \
            dpkg-dev \
            gettext \
            git \
            gnupg \
            imagemagick \
            iputils-ping \
            ispell \
            libacl1-dev \
            libasound2-dev \
            libcanberra-gtk3-module \
            libdbus-1-dev \
            libgif-dev \
            libgnutls28-dev \
            libgpm-dev \
            libgtk-3-dev \
            libjansson-dev \
            libjpeg-dev \
            liblcms2-dev \
            liblockfile-dev \
            libm17n-dev \
            libmagick++-6.q16-dev \
            libncurses5-dev \
            libotf-dev \
            libpng-dev \
            librsvg2-dev \
            libselinux1-dev \
            libtiff-dev \
            libtool \
            libxaw7-dev \
            libxml2-dev \
            openssh-client \
            perl \
            python \
            texinfo \
            wget \
            xaw3dg-dev \
            zlib1g-dev \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# https://github.com/Silex/docker-emacs

RUN git clone --depth 1 --branch emacs-27.0.91 git://git.sv.gnu.org/emacs.git /opt/emacs && \
    cd /opt/emacs && \
    ./autogen.sh && \
    ./configure --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" --with-modules && \
    make -j && \
    make install

# ============================================================
# https://github.com/nodejs/docker-node

ENV NODE_VERSION 12.18.2

RUN      curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x86.tar.xz" \
      && tar -xJf "node-v$NODE_VERSION-linux-x86.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
      && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
      && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
      # smoke tests
      && node --version \
      && npm --version \
      # install some LSP servers
      && npm i -g javascript-typescript-stdio \
      && npm i -g bash-language-server

# ============================================================
# https://hub.docker.com/r/rikorose/gcc-cmake/dockerfile

RUN wget https://github.com/Kitware/CMake/releases/download/v3.17.3/cmake-3.17.3-Linux-x86_64.sh \
      --no-check-certificate \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && /tmp/cmake-install.sh --skip-license --prefix=/usr/local \
      && rm /tmp/cmake-install.sh

# ============================================================
# ninja

RUN wget https://github.com/ninja-build/ninja/releases/download/v1.10.0/ninja-linux.zip \
      --no-check-certificate \
      && unzip ninja-linux.zip \
      && cp ninja /usr/local/bin

# ============================================================
# Build EAR (BEAR)

RUN git clone --depth 1 --branch v2.4.3 https://github.com/rizsotto/Bear.git /opt/bear && \
    cd /opt/bear && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make all -j4 && \
    make install

# ============================================================
# Build clangd

RUN git clone --depth 1 https://github.com/llvm/llvm-project.git && \
    mkdir llvm-project/build-clangd && \
    cd llvm-project/build-clangd && \
    cmake -G Ninja \
          ../llvm -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
          -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_TARGETS_TO_BUILD="X86" && \
    ninja clangd clang-format clangd-fuzzer clangd-indexer -j 40 && \
    mkdir clangd-latest && \
    cd clangd-latest && \
    mkdir bin && \
    mkdir lib && \
    cp ../bin/clangd* ./bin/ && \
    cp ../bin/clang-format ./bin/ && \
    cp -r ../lib/clang ./lib/ && \
    cp -r ./* /usr/local

# ============================================================
# https://github.com/Starefossen/docker-aspell

ENV ASPELL_SERVER ftp://ftp.gnu.org/gnu/aspell
ENV ASPELL_VERSION 0.60.6.1
ENV ASPELL_EN 2015.04.24-0

RUN     curl -SLO "${ASPELL_SERVER}/aspell-${ASPELL_VERSION}.tar.gz" \
     && curl -SLO "${ASPELL_SERVER}/dict/en/aspell6-en-${ASPELL_EN}.tar.bz2" \
     && tar -xzf "/aspell-${ASPELL_VERSION}.tar.gz" \
     && tar -xjf "/aspell6-en-${ASPELL_EN}.tar.bz2" \

     && cd "/aspell-${ASPELL_VERSION}" \
       && ./configure \
       && make -j4 \
       && make install \
       && ldconfig \

     && cd "/aspell6-en-${ASPELL_EN}" \
       && ./configure \
       && make -j4 \
       && make install \

     && rm -rf /aspell* /var/lib/apt/lists/*

# ********************************************************************************
#
# satge 1
# ********************************************************************************

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

COPY --from=builder /usr/local /usr/local

# RUN ldconfig

WORKDIR /workspace
