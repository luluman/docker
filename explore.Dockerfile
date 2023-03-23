ARG UBUNTU_VERSION=22.04
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
    libsqlite3-dev \
    libgccjit-11-dev \
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

# install tree-sitter
# https://www.reddit.com/r/emacs/comments/z25iyx/comment/ixll68j/?utm_source=share&utm_medium=web2x&context=3
ENV CC="gcc-11" CFLAGS="-O3 -Wall -Wextra"
RUN git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git /opt/tree-sitter && \
    cd /opt/tree-sitter && \
    # NOTE: update version in Makefile to 0.20.7
    sed -i 's/^VERSION := 0\.6\.3$/VERSION := 0.20.7/' Makefile && \
    make -j4 && \
    make install

RUN ldconfig
ENV CFLAGS="-O2"
RUN git clone --depth 1 --branch emacs-29 https://github.com/emacs-mirror/emacs /opt/emacs && \
    cd /opt/emacs && \
    ./autogen.sh && \
    ./configure --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    --with-modules \
    --with-native-compilation \
    --with-tree-sitter \
    --with-json \
    --with-sqlite3 \
    --with-gif=ifavailable \
    --prefix=/usr/local && \
    make NATIVE_FULL_AOT=1 -j30 && \
    make install-strip

# ============================================================
# tree-sitter-language
# https://github.com/orzechowskid/emacs-docker/blob/main/src/build-ts-modules.sh
# https://github.com/emacs-mirror/emacs/tree/master/admin/notes/tree-sitter
# https://emacs-china.org/t/treesit-master/22862/69
RUN apt-get update && \
    apt-get install -y g++ && \
    git clone https://github.com/casouri/tree-sitter-module /opt/tree-sitter-module && \
    cd /opt/tree-sitter-module && \
    ./batch.sh && \
    mv ./dist/* /usr/local/lib/ && \
    cd /opt/

# ============================================================
# https://github.com/nodejs/docker-node

ENV NODE_VERSION 18.15.0

RUN      curl -fsSLOk --compressed "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    && tar -xJf "node-v${NODE_VERSION}-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm /usr/local/*.md  /usr/local/LICENSE \
    && rm "node-v${NODE_VERSION}-linux-x64.tar.xz" \
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
    && npm i --location=global markdownlint-cli

# ============================================================
# https://hub.docker.com/r/rikorose/gcc-cmake/dockerfile

ENV CMAKE_VERSION 3.25.3

RUN wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.sh \
    --no-check-certificate \
    -q -O /tmp/cmake-install.sh \
    && chmod u+x /tmp/cmake-install.sh \
    && /tmp/cmake-install.sh --skip-license --prefix=/usr/local \
    && rm /tmp/cmake-install.sh

# ============================================================
# ninja

ENV NINJA_VERSION 1.11.1

RUN wget https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip \
    --no-check-certificate \
    && unzip ninja-linux.zip \
    && cp ninja /usr/local/bin

# ============================================================
# https://github.com/protocolbuffers/protobuf/blob/master/src/README.md
# install latest protobuf

ARG PROTOBUF_VERSION=3.20.2

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

ENV BEAR_VERSION 3.1.1

RUN apt-get install -y libssl-dev && \
    ldconfig

RUN git clone --depth 1 --branch $BEAR_VERSION https://github.com/rizsotto/Bear.git /opt/bear && \
    cd /opt/bear && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DENABLE_UNIT_TESTS=OFF -DENABLE_FUNC_TESTS=OFF && \
    make all -j4 && \
    make install


# ============================================================
# Build Aspell
# https://github.com/Starefossen/docker-aspell

ENV ASPELL_SERVER https://ftp.gnu.org/gnu/aspell
ENV ASPELL_VERSION 0.60.8
ENV ASPELL_EN 2020.12.07-0

RUN apt-get install -y bzip2 && \
    ldconfig

RUN    wget "${ASPELL_SERVER}/aspell-${ASPELL_VERSION}.tar.gz" \
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

ENV FD_VERSION=8.7.0
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
# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/dockerfiles/partials/ubuntu/bazelbuild.partial.Dockerfile
# Install bazel

ARG BAZEL_VERSION=5.3.0
RUN mkdir /bazel && \
    wget --no-check-certificate \
    -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
    chmod +x /bazel/installer.sh && \
    /bazel/installer.sh && \
    rm -f /bazel/installer.sh

# ============================================================
# https://github.com/vincent-picaud/Bazel_and_CompileCommands
# install Bazel_and_CompileCommands :) // really great and helpful

RUN    cd "${INSTALL_DIR}" \
    && curl -SLOk "https://github.com/vincent-picaud/Bazel_and_CompileCommands/archive/master.zip" \
    && unzip master.zip && rm master.zip \
    && ln -f -s "${INSTALL_DIR}/Bazel_and_CompileCommands-master/create_compile_commands.sh" /usr/local/bin/bazel-create-cc \
    && ln -f -s "${INSTALL_DIR}/Bazel_and_CompileCommands-master/setup_compile_commands.sh" /usr/local/bin/bazel-setup-cc

COPY scripts/legalize_compile_commands.sh /usr/local/lib/Bazel_and_CompileCommands-master/
RUN  ln -f -s "${INSTALL_DIR}/Bazel_and_CompileCommands-master/legalize_compile_commands.sh" /usr/local/bin/bazel-legalize-cc

# ============================================================
# other scripts

RUN mkdir /usr/local/share/bash-color
COPY scripts/terminfo-24bit.src /usr/local/share/bash-color/


# ============================================================
# download latest clangd
# use lastversion
RUN apt-get update && \
    apt-get install -y \
    python3-pip && \
    pip3 install -U setuptools pip && \
    pip3 install lastversion && \
    lastversion --assets --filter clangd-linux download https://github.com/clangd/clangd/releases && \
    unzip clangd-linux*.zip && \
    cp -r ./clangd*/* /usr/local

# ============================================================
# download latest shfmt

RUN lastversion --assets --filter _linux_amd64 download https://github.com/mvdan/sh/releases && \
    mv shfmt*linux_amd64 shfmt && \
    chmod +x ./shfmt && \
    cp ./shfmt /usr/local/bin/


# ============================================================
# download flatbuffer-compiler

RUN lastversion --assets --filter Linux.flatc.binary.g download https://github.com/google/flatbuffers/releases && \
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

# ==========================================================
# install groovy-lsp
RUN apt-get update && \
    apt-get install -y default-jre && \
    git clone https://github.com/GroovyLanguageServer/groovy-language-server && \
    cd groovy-language-server && \
    ./gradlew build && \
    cp build/libs/* /usr/local/lib/

# ==========================================================
# install mosh
RUN apt-get update && \
    apt-get install -y \
    pkg-config libutempter-dev zlib1g-dev libncurses5-dev \
    libssl-dev bash-completion tmux less && \
    git clone --branch=mosh-1.4.0 https://github.com/mobile-shell/mosh && \
    cd mosh && \
    ./autogen.sh && \
    ./configure && \
    make && make install

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
    libgccjit-11-dev \
    # for vterm
    libtool \
    libtool-bin \
    # for monkeytype
    fortune \
    fortunes \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip --no-cache-dir install --upgrade \
    pip \
    setuptools

# Some TF tools expect a "python" binary
RUN ln -s $(which python3) /usr/local/bin/python

# ================================================================================
# some others
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    valgrind \
    python3-dev \
    python3-venv \
    virtualenv \
    swig \
    openssh-client \
    gdb g++ \
    # onnx-mlir
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    libffi-dev \
    liblzma-dev \
    # tectonic
    libfreetype6-dev \
    libssl-dev \
    libfontconfig1-dev \
    # dev needed
    parallel \
    rsync \
    # for groovy
    default-jre \
    # for mosh-server
    libutempter-dev \
    # ping network
    iputils-ping \
    # SQL
    sqlite3 postgresql-client \
    wget curl \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ================================================================================
#  tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.gpg | apt-key add - && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    # mosh-server config locales
    apt-get install -y tailscale openssh-server locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # setup SSH server
    sed -i /etc/ssh/sshd_config \
    -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
    -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
    -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
    -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
    -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd

# ================================================================================

COPY --from=builder0 /usr/local /usr/local
# emacs bug
RUN find /usr/local/lib/emacs/ -name native-lisp | xargs -I{} ln -s {} /usr/

ENV SHELL "/bin/bash"

# https://askubuntu.com/a/1060694
RUN ldconfig && \
    locale-gen "en_US.UTF-8" && \
    update-locale LC_ALL="en_US.UTF-8"

# start SSH server
COPY scripts/start.sh /usr/bin/start.sh
RUN chmod +x /usr/bin/start.sh

CMD "start.sh"

WORKDIR /workspace
