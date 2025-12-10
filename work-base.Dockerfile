ARG UBUNTU_VERSION=22.04
ARG UBUNTU_NAME=jammy
ARG DEBIAN_FRONTEND="noninteractive"

# ==========================================================
# stage 0

FROM ubuntu:${UBUNTU_VERSION} AS builder
ARG UBUNTU_NAME
ARG DEBIAN_FRONTEND

RUN apt-get update && \
    apt-get install -y software-properties-common gpg-agent && \
    apt-add-repository ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y \
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
    libxpm-dev \
    libgnutls28-dev \
    libncurses5-dev \
    libxml2-dev \
    libxt-dev \
    gcc-multilib \
    librsvg2-dev \
    libsqlite3-dev \
    libgccjit-13-dev \
    # libgccjit-11 needs gcc-12 ?
    gcc-13 g++-13 \
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
    # other package needed
    wget \
    unzip

# install tree-sitter
# https://www.reddit.com/r/emacs/comments/z25iyx/comment/ixll68j/?utm_source=share&utm_medium=web2x&context=3
ENV CC="gcc-13" CFLAGS="-O3 -Wall -Wextra"
RUN git clone --depth 1 --branch v0.25.9 https://github.com/tree-sitter/tree-sitter.git /opt/tree-sitter && \
    cd /opt/tree-sitter && \
    make -j4 && \
    make install

RUN ldconfig
ENV CFLAGS="-O2"
RUN git clone https://github.com/emacs-mirror/emacs /opt/emacs && \
    cd /opt/emacs && \
    git checkout 45a82437a3ea651db9efa3215588cd828e06c79c && \
    ./autogen.sh && \
    ./configure --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    --with-modules \
    --with-native-compilation \
    --with-tree-sitter \
    --with-sqlite3 \
    --with-gif=ifavailable \
    --with-jpeg=ifavailable \
    --with-tiff=ifavailable \
    # no need GUI and silent the `--with-x-toolkit=lucid` warning.
    --without-x --without-x-toolkit-scroll-bars \
    --prefix=/usr/local && \
    make NATIVE_FULL_AOT=1 -j30 && \
    make install-strip && \
    rm -r /opt/emacs

# ============================================================
# tree-sitter-language
# https://github.com/orzechowskid/emacs-docker/blob/main/src/build-ts-modules.sh
# https://github.com/emacs-mirror/emacs/tree/master/admin/notes/tree-sitter
# https://emacs-china.org/t/treesit-master/22862/69
RUN apt-get update && \
    apt-get install -y g++ && \
    git clone --branch v2.5 https://github.com/casouri/tree-sitter-module /opt/tree-sitter-module && \
    cd /opt/tree-sitter-module && \
    sed -i "/languages=(/a \ \ \ \ 'jsdoc'" batch.sh && \
    ./batch.sh && \
    mv ./dist/* /usr/local/lib/ && \
    cd /opt/

# ============================================================
# Install GDB
# https://www.linuxfromscratch.org/blfs/view/svn/general/gdb.html
ENV GDB_VERSION 16.3

RUN apt-get update && \
    apt-get install -y python3-dev libmpfr-dev libgmp-dev libreadline-dev && \
    wget https://sourceware.org/pub/gdb/releases/gdb-${GDB_VERSION}.tar.gz && \
    tar -xf gdb-${GDB_VERSION}.tar.gz && \
    cd gdb-${GDB_VERSION} && \
    ./configure --with-python=/usr/bin/python3 --prefix=/usr/local --with-system-readline && \
    make -j30 && make install

# ============================================================
# https://github.com/nodejs/docker-node

ENV NODE_VERSION 24.11.1

RUN apt-get update && \
    apt-get install xz-utils && \
    curl -fsSLOk --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
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
    && npm i --location=global yaml-language-server \
    && npm i --location=global markdownlint-cli \
    && npm i --location=global @google/gemini-cli \
    && npm i --location=global @anthropic-ai/claude-code \
    && npm i --location=global @openai/codex

# ============================================================
# https://hub.docker.com/r/rikorose/gcc-cmake/dockerfile

ENV CMAKE_VERSION 4.1.0

RUN wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.sh \
    --no-check-certificate \
    -q -O /tmp/cmake-install.sh \
    && chmod u+x /tmp/cmake-install.sh \
    && /tmp/cmake-install.sh --skip-license --prefix=/usr/local \
    && rm /tmp/cmake-install.sh

# ============================================================
# Build Aspell
# https://github.com/Starefossen/docker-aspell

ENV ASPELL_SERVER http://mirror.keystealth.org/gnu/aspell
ENV ASPELL_VERSION 0.60.8.1
ENV ASPELL_EN 2020.12.07-0

RUN apt-get install -y bzip2 && \
    ldconfig

RUN wget "${ASPELL_SERVER}/aspell-${ASPELL_VERSION}.tar.gz" \
    && wget "${ASPELL_SERVER}/dict/en/aspell6-en-${ASPELL_EN}.tar.bz2" \
    && tar -xzf "aspell-${ASPELL_VERSION}.tar.gz" \
    && tar -xjf "aspell6-en-${ASPELL_EN}.tar.bz2" \
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
    && make install

# ============================================================
# Build libEnchant for jinx

ENV ENCHANT_VERSION 2.6.9

RUN apt-get update && apt-get install -y libglib2.0-dev groff && \
    wget "https://github.com/rrthomas/enchant/releases/download/v${ENCHANT_VERSION}/enchant-${ENCHANT_VERSION}.tar.gz" \
    && tar -xf "enchant-${ENCHANT_VERSION}.tar.gz" \
    # build
    && cd "enchant-${ENCHANT_VERSION}" \
    && test -f configure \
    && ./configure \
    && make \
    && make install \
    && ldconfig

# ============================================================
# https://hub.docker.com/r/peccu/rg/dockerfile
# build ripgrep

ENV RG_VERSION=15.1.0
RUN     set -x \
    &&  wget https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    --no-check-certificate \
    &&  tar xzf ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    &&  mv ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg /usr/local/bin/

# ============================================================
# get jq

ENV JQ_VERSION=1.7.1
RUN     set -x \
    &&  wget https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64 \
    --no-check-certificate -O jq \
    &&  chmod +x ./jq \
    &&  mv ./jq /usr/local/bin/

# ============================================================
# build fd-find

ENV FD_VERSION=9.0.0
RUN     set -x \
    &&  wget https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
    --no-check-certificate \
    &&  tar xzf fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
    &&  mv fd-v${FD_VERSION}-x86_64-unknown-linux-gnu/fd /usr/local/bin/

# ============================================================
# other scripts

RUN mkdir /usr/local/share/bash-color
COPY scripts/terminfo-24bit.src /usr/local/share/bash-color/

# ============================================================
# download latest shfmt
ENV SHFMT_VERSION=3.7.0
RUN wget https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_amd64 && \
    mv shfmt*linux_amd64 shfmt && \
    chmod +x ./shfmt && \
    cp ./shfmt /usr/local/bin/

# ==========================================================
# install rust-analyzer
RUN curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > /usr/local/bin/rust-analyzer \
    && chmod +x /usr/local/bin/rust-analyzer

# ==========================================================
# install mosh
RUN apt-get update && \
    apt-get install -y \
    automake \
    pkg-config protobuf-compiler libprotobuf-dev libutempter-dev zlib1g-dev libncurses5-dev \
    libssl-dev bash-completion tmux less && \
    # https://github.com/mobile-shell/mosh/issues/1134
    git clone --branch=mosh-1.4.0+blink-17.3.0 https://github.com/blinksh/mosh-server && \
    cd mosh-server && \
    ./autogen.sh && \
    ./configure && \
    make && make install

# ==========================================================
# install clash
COPY clash_config/clash /usr/local/bin/
RUN  chmod +x /usr/local/bin/clash

# ==========================================================
# install llvm tools
ENV LLVM_VERSION=21.1.7
RUN cd /opt/ && rm -rf /opt/* /tmp/* && \
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-X64.tar.xz && \
    tar xf LLVM-${LLVM_VERSION}-Linux-X64.tar.xz && \
    cd LLVM-${LLVM_VERSION}-Linux-X64/bin && \
    cp llvm-cxxfilt llvm-symbolizer /usr/local/bin/ && \
    cp *lsp-server /usr/local/bin/ && \
    rm -r /opt/*

# ==========================================================
# stage 1

FROM ubuntu:${UBUNTU_VERSION} AS release
ARG UBUNTU_NAME
ARG DEBIAN_FRONTEND

RUN rm -rf /usr/local/man

COPY --from=builder /usr/local /usr/local
