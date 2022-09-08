ARG UBUNTU_VERSION=18.04
ARG DEBIAN_FRONTEND="noninteractive"

# ********************************************************************************
#
# satge 0
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder0
ARG DEBIAN_FRONTEND

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    autoconf \
    texinfo \
    binutils \
    flex \
    bison \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    coreutils \
    make \
    libtinfo5 \
    texinfo \
    libjpeg-dev \
    libtiff-dev \
    libgif-dev \
    libxpm-dev \
    libgtk-3-dev \
    libgnutls28-dev \
    libncurses5-dev \
    libxml2-dev \
    libxt-dev \
    libjansson4 \
    gcc-multilib \
    libcanberra-gtk3-module \
    libjansson-dev \
    librsvg2-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --global http.sslVerify false

# ============================================================
# https://www.masteringemacs.org/article/speed-up-emacs-libjansson-native-elisp-compilation
# https://gitlab.com/koral/emacs-nativecomp-dockerfile/-/blob/master/Dockerfile

RUN apt-get update \
    && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    # other package needed
    wget \
    unzip

RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update -y \
    && apt-get install -y gcc-11 libgccjit0 libgccjit-11-dev

RUN ldconfig
ENV CC="gcc-11"
RUN git clone --depth 1 --branch emacs-28 https://github.com/emacs-mirror/emacs /opt/emacs && \
    cd /opt/emacs && \
    ./autogen.sh && \
    ./configure --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    --with-modules \
    --with-native-compilation \
    --prefix=/usr/local && \
    make NATIVE_FULL_AOT=1 -j30 && \
    make install-strip

# ============================================================
# https://github.com/nodejs/docker-node

ENV NODE_VERSION 16.17.0

RUN      curl -fsSLOk --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm /usr/local/*.md  /usr/local/LICENSE \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    # smoke tests
    && node --version \
    && npm --version \
    # install some LSP servers
    # && npm config set registry https://registry.npm.taobao.org \
    && npm i --location=global typescript typescript-language-server \
    && npm i --location=global bash-language-server \
    && npm i --location=global pyright \
    && npm i --location=global dockerfile-language-server-nodejs \
    && npm i --location=global vscode-langservers-extracted  \
    && npm i --location=global yaml-language-server


# ============================================================
# https://hub.docker.com/r/rikorose/gcc-cmake/dockerfile

ENV CMAKE_VERSION 3.23.3

RUN wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.sh \
    --no-check-certificate \
    -q -O /tmp/cmake-install.sh \
    && chmod u+x /tmp/cmake-install.sh \
    && /tmp/cmake-install.sh --skip-license --prefix=/usr/local \
    && rm /tmp/cmake-install.sh

# ============================================================
# ninja

ENV NINJA_VERSION 1.11.0

RUN wget https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip \
    --no-check-certificate \
    && unzip ninja-linux.zip \
    && cp ninja /usr/local/bin

# ============================================================
# https://github.com/protocolbuffers/protobuf/blob/master/src/README.md
# install latest protobuf

ARG PROTOBUF_VERSION=3.20.0

RUN apt-get install -y autoconf automake libtool curl make g++ unzip && \
    git clone --depth 1 --recursive --branch v${PROTOBUF_VERSION} https://github.com/protocolbuffers/protobuf.git && \
    cd protobuf && \
    ./autogen.sh && \
    ./configure && \
    make -j10 && \
    make install && \
    ldconfig

# ============================================================
# Build EAR (BEAR)

ENV BEAR_VERSION 2.4.4

RUN git clone --depth 1 --branch $BEAR_VERSION https://github.com/rizsotto/Bear.git /opt/bear && \
    cd /opt/bear && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make all -j4 && \
    make install

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

ENV RG_VERSION=13.0.0
RUN     set -x \
    &&  wget https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    --no-check-certificate \
    &&  tar xzf ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    &&  mv ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg /usr/local/bin/

# ============================================================
# build fd-find

ENV FD_VERSION=8.4.0
RUN     set -x \
    &&  wget https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
    --no-check-certificate \
    &&  tar xzf fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
    &&  mv fd-v${FD_VERSION}-x86_64-unknown-linux-gnu/fd /usr/local/bin/

# ============================================================
# https://github.com/Valian/docker-git-lfs
# build git-lfs

ENV GITLFS_VERSION=3.0.2
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


# ============================================================
# download latest clangd

RUN curl -s https://github.com/clangd/clangd/releases \
    | grep "clangd-linux-snapshot" \
    | cut -d '"' -f 2 \
    | head -n 1 \
    | wget --no-check-certificate --base=http://github.com/ -i - && \
    unzip clangd-linux-snapshot*.zip && \
    cp -r ./clangd_snapshot_*/* /usr/local

# ============================================================
# download flat-buffer-compiler

RUN curl -s https://github.com/google/flatbuffers/releases \
    | grep "Linux.flatc" \
    | cut -d '"' -f 2 \
    | head -n 1 \
    | wget --no-check-certificate --base=http://github.com/ -i - && \
    unzip Linux.flatc.binary*.zip && \
    chmod +x ./flatc && \
    cp ./flatc /usr/local/bin/

# ===========================================================
# install ccache

RUN git clone https://github.com/ccache/ccache --branch=1 --branch v4.6 && \
    cd ccache && \
    mkdir build && \
    cd build && \
    cmake -DZSTD_FROM_INTERNET=ON \
    -DHIREDIS_FROM_INTERNET=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release .. && \
    make && make install


# ===========================================================
# install fuz (fuzzy match scoring/matching functions for Emacs)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    apt-get update && apt-get install -y clang llvm && \
    git clone https://github.com/rustify-emacs/fuz.el fuz

ENV PATH="/root/.cargo/bin:${PATH}"
RUN cd fuz && \
    cargo build --release && \
    cp target/release/libfuz_core.so /usr/local/lib/

# ==========================================================
# install rust-analyzer
RUN curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > /usr/local/bin/rust-analyzer \
    && chmod +x /usr/local/bin/rust-analyzer

# ********************************************************************************
#
# stage 1
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS base
ARG DEBIAN_FRONTEND
# ================================================================================
# dependency of Emacs
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libmpc3 \
    libmpfr6 \
    libgmp10 \
    coreutils \
    libjpeg-turbo8 \
    libtiff5 \
    libgif7 \
    libxpm4 \
    libgtk-3-0 \
    libgnutlsxx28 \
    libncurses5 \
    libxml2 \
    libxt6 \
    libjansson4 \
    libcanberra-gtk3-module \
    libx11-xcb1 \
    binutils \
    libc6-dev \
    librsvg2-2 \
    # for vterm
    libtool \
    libtool-bin \
    # for monkeytype
    fortune \
    fortunes \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN apt-get update \
    && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    # other package needed
    wget \
    unzip \
    # update gcc for gccjit emacs
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update -y \
    && apt-get install -y gcc-11 g++-11 gdb libgccjit0 libgccjit-11-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ===============================================================================
# upgrade python
RUN apt-get update && \
    apt-get install -y \
    python3.7-dev \
    python3.7-venv && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.7 10 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 10 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# ================================================================================
# some others
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    # default-jre \
    valgrind \
    virtualenv \
    swig \
    openssh-client \
    # bmlang
    swig \
    # ufw
    libatlas-base-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-system-dev \
    libboost-regex-dev \
    libboost-thread-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libleveldb-dev \
    liblmdb-dev \
    libopenblas-dev \
    libhdf5-serial-dev \
    # bmnetp
    libnuma1 \
    # bmnetu
    liblzma-dev \
    # llvm
    libncurses-dev \
    # dev needed
    parallel \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ================================================================================
COPY --from=builder0 /usr/local /usr/local
# fix emacs bug
RUN find /usr/local/lib/emacs/ -name native-lisp | xargs -I{} ln -s {} /usr/

ENV SHELL "/bin/bash"

RUN ldconfig

WORKDIR /workspace
