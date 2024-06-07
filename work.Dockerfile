ARG UBUNTU_VERSION=20.04
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
    libgccjit-10-dev \
    # libgccjit-11 needs gcc-12 ?
    gcc-10 g++-10 \
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
ENV CC="gcc-10" CFLAGS="-O3 -Wall -Wextra"
RUN git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git /opt/tree-sitter && \
    cd /opt/tree-sitter && \
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
    --with-jpeg=ifavailable \
    --with-tiff=ifavailable \
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
# Install GDB
# https://www.linuxfromscratch.org/blfs/view/svn/general/gdb.html
RUN apt-get update && \
    apt-get install -y python3-dev libmpfr-dev libgmp-dev libreadline-dev && \
    wget https://ftp.gnu.org/gnu/gdb/gdb-14.2.tar.gz && \
    tar -xf gdb-14.2.tar.gz && \
    cd gdb-14.2 && \
    ./configure --with-python=yes --prefix=/usr/local --with-system-readline && \
    make -j30 && make install

# ============================================================
# https://github.com/nodejs/docker-node

ENV NODE_VERSION 20.11.0

RUN curl -fsSLOk --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
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

ENV RG_VERSION=14.1.0
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

# ===========================================================
# install fuz (fuzzy match scoring/matching functions for Emacs)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    apt-get update && apt-get install -y clang llvm && \
    git clone https://github.com/rustify-emacs/fuz.el fuz

ENV PATH="/root/.cargo/bin:${PATH}"
RUN cd fuz && \
    sed -i 's/fuzzy-matcher = "0\.2\.1"/fuzzy-matcher = "0.3.7"/' Cargo.toml && \
    cargo build --release && \
    cp target/release/libfuz_core.so /usr/local/lib/

# ==========================================================
# install rust-analyzer
RUN curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > /usr/local/bin/rust-analyzer \
    && chmod +x /usr/local/bin/rust-analyzer

# ==========================================================
# install mosh
RUN apt-get update && \
    apt-get install -y \
    automake \
    pkg-config protobuf-compiler libutempter-dev zlib1g-dev libncurses5-dev \
    libssl-dev bash-completion tmux less && \
    git clone --branch=mosh-1.4.0 https://github.com/mobile-shell/mosh && \
    cd mosh && \
    ./autogen.sh && \
    ./configure && \
    make && make install

# ==========================================================
# install clash
RUN curl -L https://downloads.clash.wiki/ClashPremium/clash-linux-amd64-v3-2023.08.17.gz | gunzip -c - > /usr/local/bin/clash \
    && chmod +x /usr/local/bin/clash


# ********************************************************************************
#
# stage 1
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder1
ARG DEBIAN_FRONTEND
# ================================================================================
# --no-upgrade --no-install-recommends
COPY 99-apt-get-settings /etc/apt/apt.conf.d/

# dependency of Emacs
RUN apt-get update && rm -rf /usr/local/man && \
    apt-get install -y \
    libmpc3 \
    libmpfr6 \
    libgmp10 \
    coreutils \
    libjpeg-turbo8 \
    libtiff5 \
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
    libgccjit-10-dev \
    # libgccjit-11 needs gcc-12 ?
    gcc-10 g++-10 \
    libsqlite3-dev \
    # for vterm
    libtool \
    libtool-bin \
    # for monkeytype
    fortune \
    fortunes \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ================================================================================
# some others
RUN apt-get update && ldconfig && \
    apt-get install -y \
    build-essential \
    apt-transport-https \
    gnupg-agent \
    software-properties-common \
    ca-certificates \
    valgrind \
    openssh-client \
    sudo \
    # gdb \
    libmpfr-dev libgmp-dev libreadline-dev \
    # tectonic
    libfreetype6-dev \
    libssl-dev \
    libfontconfig1-dev \
    # dev needed
    parallel \
    rsync \
    graphviz \
    # for BM
    bison \
    flex \
    bsdmainutils \
    # for mosh-server
    libutempter-dev \
    # ping network
    iputils-ping \
    netcat \
    # SQL
    sqlite3 postgresql-client \
    # smb
    smbclient \
    # python3
    python3-dev \
    python3-venv \
    python3-pip \
    virtualenv \
    tzdata \
    # tablegen
    libncurses5-dev \
    libncurses5 \
    # riscv-isa-sim
    device-tree-compiler libboost-regex-dev \
    # tools
    ninja-build \
    curl wget \
    unzip \
    ccache \
    git-lfs \
    patchelf \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clang
RUN apt-get update && apt-get install -y software-properties-common gpg-agent && \
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    apt-add-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-14 main" && \
    apt-get install -y clang-14 lld-14 clang-tidy-14 libomp-dev && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-14 100 && \
    update-alternatives --install /usr/bin/lld lld /usr/bin/lld-14 100 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-14 100 && \
    # install clang-format-18
    apt-add-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-18 main" && \
    apt-get install -y clang-format-18 lldb-18 clangd-18 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100 && \
    update-alternatives --install /usr/bin/clang-format-diff clang-format-diff /usr/bin/clang-format-diff-18 100 && \
    update-alternatives --install /usr/bin/lldb lldb /usr/bin/lldb-18 100 && \
    update-alternatives --install /usr/bin/lldb-dap lldb-dap /usr/bin/lldb-dap-18 100 && \
    update-alternatives --install /usr/bin/lldb-server lldb-server /usr/bin/lldb-server-18 100 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-18 100 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# DOCKER CLI
RUN apt-get update && apt-get install -y \
    ca-certificates gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y \
    docker-ce-cli \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Modular GPG
RUN apt-get  update && apt-get install -y apt-transport-https && \
    keyring_location=/usr/share/keyrings/modular-installer-archive-keyring.gpg && \
    curl -1sLf 'https://dl.modular.com/bBNWiLZX5igwHXeu/installer/gpg.0E4925737A3895AD.key' |  gpg --dearmor >> ${keyring_location} && \
    curl -1sLf 'https://dl.modular.com/bBNWiLZX5igwHXeu/installer/config.deb.txt?distro=debian&codename=wheezy' > /etc/apt/sources.list.d/modular-installer.list && \
    apt-get update && \
    apt-get install -y modular && \
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

# timeZone and some pip packages
RUN TZ=Asia/Shanghai \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata && \
    # packages for vpn
    pip3 install --no-cache-dir requests pyyaml

# ================================================================================
COPY --from=builder0 /usr/local /usr/local

RUN \
    # fix emacs bug
    find /usr/local/lib/emacs/ -name native-lisp | xargs -I{} ln -s {} /usr/

ENV SHELL "/bin/bash"

# https://askubuntu.com/a/1060694
RUN ldconfig && \
    locale-gen "en_US.UTF-8" && \
    update-locale LC_ALL="en_US.UTF-8"

# start SSH server
COPY scripts/start.sh /usr/bin/start.sh
COPY scripts/vpn-config.py /opt/vpn-config.py
COPY scripts/Country.mmdb /opt/Country.mmdb
RUN chmod +x /usr/bin/start.sh /opt/vpn-config.py

CMD "start.sh"

WORKDIR /workspace
