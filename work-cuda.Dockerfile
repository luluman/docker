ARG UBUNTU_VERSION=24.04
ARG CUDA_VERSION=13.1.0
ARG UBUNTU_NAME=noble
ARG DEBIAN_FRONTEND="noninteractive"

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS runtime
ARG UBUNTU_NAME
ARG DEBIAN_FRONTEND

# ================================================================================
# --no-upgrade --no-install-recommends
COPY 99-apt-get-settings /etc/apt/apt.conf.d/

# dependency of Emacs
RUN apt-get update && \
    apt-get install -y software-properties-common gpg-agent && \
    rm -rf /usr/local/man && \
    apt-get install -y  \
    libmpc3 \
    libmpfr6 \
    libgmp10 \
    coreutils \
    libjpeg-turbo8 \
    libtiff6 \
    libxpm4 \
    # can not find libgnutlsxx28
    libgnutls28-dev \
    libncurses6 \
    libxml2 \
    libxt6 \
    libx11-xcb1 \
    binutils \
    libc6-dev \
    librsvg2-2 \
    libgccjit-13-dev \
    gcc g++ \
    libsqlite3-dev \
    # for vterm
    libtool \
    libtool-bin \
    # libenchant for jinx
    libglib2.0-dev \
    # for monkeytype
    fortune \
    fortunes \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ================================================================================
# some others
RUN apt-get update && ldconfig && \
    apt-get install -y   \
    build-essential \
    apt-transport-https \
    ca-certificates \
    valgrind \
    openssh-client \
    sudo \
    # clang find 14
    libstdc++-14-dev \
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
    bear \
    # for BM
    bison \
    flex \
    bsdmainutils \
    # for mosh-server
    libprotobuf-dev \
    libutempter-dev \
    # ping network
    iputils-ping \
    netcat-traditional \
    # test storage performance
    fio \
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
    libncurses-dev \
    libncurses6 \
    # riscv-isa-sim
    device-tree-compiler libboost-regex-dev libboost-system-dev \
    # tools
    ninja-build \
    curl wget \
    unzip \
    ccache \
    git-lfs \
    patchelf \
    shellcheck \
    # linux
    libelf-dev \
    fakeroot \
    bc \
    # https://youtu.be/QlzoegSuIzg?si=tDkVGrNi54yjhhcP
    cpio \
    # boot loader
    syslinux \
    dosfstools \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clang
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    apt-add-repository "deb http://apt.llvm.org/${UBUNTU_NAME}/ llvm-toolchain-${UBUNTU_NAME}-18 main" && \
    apt-get install -y  clang-18 lld-18 libomp-dev libc++-18-dev libc++abi-18-dev && \
    # clang config
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 && \
    update-alternatives --install /usr/bin/lld lld /usr/bin/lld-18 100 && \
    # install clang-format-22
    apt-add-repository "deb http://apt.llvm.org/${UBUNTU_NAME}/ llvm-toolchain-${UBUNTU_NAME}-22 main" && \
    apt-get install -y  clang-format-22 clang-tidy-22 lldb-22 clangd-22 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-22 100 && \
    update-alternatives --install /usr/bin/clang-format-diff clang-format-diff /usr/bin/clang-format-diff-22 100 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-22 100 && \
    update-alternatives --install /usr/bin/lldb lldb /usr/bin/lldb-22 100 && \
    update-alternatives --install /usr/bin/lldb-dap lldb-dap /usr/bin/lldb-dap-22 100 && \
    update-alternatives --install /usr/bin/lldb-server lldb-server /usr/bin/lldb-server-22 100 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-22 100 && \
    # config gcc
    # update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 10 --slave /usr/bin/g++ g++ /usr/bin/g++-13 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# DOCKER CLI
RUN apt-get update && apt-get install -y  \
    ca-certificates gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y  \
    docker-ce-cli \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install WezTerm terminal emulator for multiplexing
RUN curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | tee /etc/apt/sources.list.d/wezterm.list && \
    chmod 644 /usr/share/keyrings/wezterm-fury.gpg && \
    apt-get update && \
    apt-get install -y --no-install-recommends wezterm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ================================================================================
#  tailscale

RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_NAME}.gpg | apt-key add - && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_NAME}.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    # mosh-server config locales
    apt-get install -y  tailscale openssh-server locales && \
    apt-get clean && \
    # fix compatible issue with Linux-kernel
    # https://github.com/tailscale/tailscale/issues/14410#issuecomment-2551427726
    echo 'TS_DEBUG_FIREWALL_MODE=nftables' >> /etc/default/tailscaled && \
    rm -rf /var/lib/apt/lists/* && \
    # setup SSH server
    sed -i /etc/ssh/sshd_config \
    -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
    -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
    -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
    -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
    -e 's/^#\?UsePAM.*/UsePAM no/' \
    -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir -p /var/run/sshd

# timeZone and some pip packages
RUN TZ=Asia/Shanghai \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

# ================================================================================
COPY --from=mattlu/work-builder:latest /usr/local /usr/local

RUN \
    # fix emacs bug
    find /usr/local/lib/emacs/ -name native-lisp | xargs -I{} ln -s {} /usr/


ENV SHELL="/bin/bash"

# https://askubuntu.com/a/1060694
RUN ldconfig && \
    locale-gen "en_US.UTF-8" && \
    update-locale LC_ALL="en_US.UTF-8"

# start SSH server
COPY scripts/start.sh /usr/bin/start.sh

CMD "start.sh"

WORKDIR /workspace
