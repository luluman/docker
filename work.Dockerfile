ARG UBUNTU_VERSION=16.04

# ********************************************************************************
#
# stage 0
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder0

# COPY ./sources.list /etc/apt/sources.list

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
            python3-dev \
            texinfo \
            unzip \
            wget \
            xaw3dg-dev \
            zlib1g-dev \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --global http.sslVerify false

# ============================================================
# https://github.com/Silex/docker-emacs

RUN git clone --depth 1 --branch emacs-27 https://github.com/emacs-mirror/emacs /opt/emacs && \
    cd /opt/emacs && \
    ./autogen.sh && \
    ./configure --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" --with-modules && \
    make -j30 && \
    make install


# ********************************************************************************
#
# stage 1
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder1

# dependency of llvm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            git \
            curl \
            python3-dev \
            unzip \
            wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --global http.sslVerify false
COPY --from=builder0 /usr/local /usr/local

# ============================================================
# https://github.com/nodejs/docker-node

ENV NODE_VERSION 14.16.0

RUN      curl -fsSLOk --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
      && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
      && rm "node-v$NODE_VERSION-linux-x64.tar.xz" \
      && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
      # smoke tests
      && node --version \
      && npm --version \
      # install some LSP servers
      # && npm config set registry https://registry.npm.taobao.org \
      && npm i -g javascript-typescript-langserver \
      && npm i -g bash-language-server

# ============================================================
# https://hub.docker.com/r/rikorose/gcc-cmake/dockerfile

ENV CMAKE_VERSION 3.20.0

RUN wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-Linux-x86_64.sh \
      --no-check-certificate \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && /tmp/cmake-install.sh --skip-license --prefix=/usr/local \
      && rm /tmp/cmake-install.sh

# ============================================================
# ninja

ENV NINJA_VERSION 1.10.2

RUN wget https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip \
      --no-check-certificate \
      && unzip ninja-linux.zip \
      && cp ninja /usr/local/bin

# ============================================================
# Build EAR (BEAR)

ENV BEAR_VERSION 2.4.4

RUN git clone --depth 1 --branch $BEAR_VERSION https://github.com/rizsotto/Bear.git /opt/bear && \
    cd /opt/bear && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make all -j4 && \
    make install

# ============================================================
# Build YCMD
# https://github.com/AlexandreCarlton/ycmd-docker

# master drop python3.5 support, fallback to 0abcfafbaf57e4d4d499680c13e1413a34672a58
RUN git clone --recursive https://github.com/ycm-core/ycmd && \
    cd ycmd && \
    git checkout  0abcfafbaf57e4d4d499680c13e1413a34672a58 && \
    git submodule update --init --recursive && \
    python3 build.py \
          --clang-completer \
          --ts-completer \
          --ninja && \
    mkdir build && \
    cp CORE_VERSION ./build/ && \
    cp -r third_party ./build/ && \
    cp -r ycmd ./build/ && \
    cp -r examples ./build/ && \
    cp ycm_core.so ./build/ && \
    cp -r ./build /usr/local/lib/ycmd

# ============================================================
# Build Aspell
# https://github.com/Starefossen/docker-aspell

ENV ASPELL_SERVER ftp://ftp.gnu.org/gnu/aspell
ENV ASPELL_VERSION 0.60.8
ENV ASPELL_EN 2019.10.06-0

RUN     curl -SLOk "${ASPELL_SERVER}/aspell-${ASPELL_VERSION}.tar.gz" \
     && curl -SLOk "${ASPELL_SERVER}/dict/en/aspell6-en-${ASPELL_EN}.tar.bz2" \
     && tar -xzf "/aspell-${ASPELL_VERSION}.tar.gz" \
     && tar -xjf "/aspell6-en-${ASPELL_EN}.tar.bz2" \
     # build
     && cd "/aspell-${ASPELL_VERSION}" \
       && ./configure \
       && make -j4 \
       && make install \
       && ldconfig \
     # copy
     && cd "/aspell6-en-${ASPELL_EN}" \
       && ./configure \
       && make -j4 \
       && make install \
     # cleanup
     && rm -rf /aspell* /var/lib/apt/lists/*

# ============================================================
# https://hub.docker.com/r/peccu/rg/dockerfile
# build ripgrep

ENV RG_VERSION=12.1.1
RUN     set -x \
    &&  wget https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz \
             --no-check-certificate \
    &&  tar xzf ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    &&  mv ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg /usr/local/bin/

# ============================================================
# https://github.com/Valian/docker-git-lfs
# build git-lfs

ENV GITLFS_VERSION=2.13.2

RUN    wget https://github.com/git-lfs/git-lfs/releases/download/v$GITLFS_VERSION/git-lfs-linux-amd64-v$GITLFS_VERSION.tar.gz \
            -c --retry-connrefused --tries=0 --timeout=180 --no-check-certificate \
    && tar -zxf git-lfs-linux-amd64-v$GITLFS_VERSION.tar.gz \
    && mv git-lfs /usr/local/bin/ \
    && rm -rf git-lfs-* \
    && rm -rf install.sh

# ============================================================
# other scripts

RUN mkdir /usr/local/share/bash-color
COPY scripts/terminfo-24bit.src /usr/local/share/bash-color/

# ********************************************************************************
#
# stage 2
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder2

# ================================================================================
# dependency of llvm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            git \
            python3-dev \
            pkg-config \
            libz-dev \
            libc-ares-dev \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --global http.sslVerify false
COPY --from=builder1 /usr/local /usr/local

# ============================================================
# Build clangd
# https://github.com/clangd/clangd/blob/master/.github/workflows/autobuild.yaml

RUN git clone --depth 1 https://github.com/llvm/llvm-project.git && \
    mkdir llvm-project/build-clangd && \
    cd llvm-project/build-clangd && \
    cmake -G Ninja \
          ../llvm -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
          -DCMAKE_EXE_LINKER_FLAGS_RELEASE=-static-libgcc -Wl,--compress-debug-sections=zlib \
          -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
          -DLLVM_ENABLE_ZLIB=FORCE_ON \
          -DLLVM_ENABLE_ASSERTIONS=OFF \
          -DLLVM_ENABLE_BACKTRACES=ON \
          -DLLVM_ENABLE_TERMINFO=OFF \
          -DCMAKE_BUILD_TYPE=Release \
          -DCLANG_PLUGIN_SUPPORT=OFF \
          -DLLVM_ENABLE_PLUGINS=OFF \
          -DLLVM_INCLUDE_TESTS=NO && \
    ninja clangd clang-format clang-tidy clangd-indexer && \
    mkdir clangd-latest && \
    cd clangd-latest && \
    mkdir bin && \
    mkdir lib && \
    cp ../bin/clangd* ./bin/ && \
    cp ../bin/clang-format ./bin/ && \
    cp ../bin/clang-tidy ./bin/ && \
    cp -r ../lib/clang ./lib/ && \
    cp -r ./* /usr/local


# ********************************************************************************
#
# stage 3
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS base

# COPY ./sources.list /etc/apt/sources.list

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
            # llvm needed
            libz-dev \
            libc-ares-dev \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# ================================================================================

COPY --from=builder2 /usr/local /usr/local

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV SHELL "/bin/bash"

RUN ldconfig

WORKDIR /workspace
