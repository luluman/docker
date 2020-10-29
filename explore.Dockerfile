ARG UBUNTU_VERSION=20.04

# ********************************************************************************
#
# satge 0
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder0

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

# ============================================================
# https://github.com/nodejs/docker-node

ENV NODE_VERSION 14.15.0

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
      && npm i -g javascript-typescript-langserver \
      && npm i -g bash-language-server

# ============================================================
# https://hub.docker.com/r/rikorose/gcc-cmake/dockerfile

ENV CMAKE_VERSION 3.18.4

RUN wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-Linux-x86_64.sh \
      --no-check-certificate \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && /tmp/cmake-install.sh --skip-license --prefix=/usr/local \
      && rm /tmp/cmake-install.sh

# ============================================================
# ninja

ENV NINJA_VERSION 1.10.1

RUN wget https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip \
      --no-check-certificate \
      && unzip ninja-linux.zip \
      && cp ninja /usr/local/bin

# ============================================================
# Build EAR (BEAR)

ENV BEAR_VERSION 3.0.0

RUN git clone --depth 1 --branch $BEAR_VERSION https://github.com/rizsotto/Bear.git /opt/bear && \
    cd /opt/bear && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local \
            -DPYTHON_EXECUTABLE=/usr/bin/python3 && \
    make all -j4 && \
    make install

# ============================================================
# Build YCMD
# https://github.com/AlexandreCarlton/ycmd-docker

RUN git clone --depth 1 --recursive https://github.com/ycm-core/ycmd && \
    cd ycmd && \
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

ENV GITLFS_VERSION=2.12.0

RUN    wget https://github.com/git-lfs/git-lfs/releases/download/v$GITLFS_VERSION/git-lfs-linux-amd64-v$GITLFS_VERSION.tar.gz \
            -c --retry-connrefused --tries=0 --timeout=180 --no-check-certificate \
    && tar -zxf git-lfs-linux-amd64-v$GITLFS_VERSION.tar.gz \
    && mv git-lfs /usr/local/bin/ \
    && rm -rf git-lfs-* \
    && rm -rf install.sh

# ============================================================
# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/dockerfiles/partials/ubuntu/bazelbuild.partial.Dockerfile
# Install bazel

ARG BAZEL_VERSION=3.1.0
RUN mkdir /bazel && \
    wget --no-check-certificate \
         -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
    chmod +x /bazel/installer.sh && \
    /bazel/installer.sh && \
    rm -f /bazel/installer.sh

# ============================================================
# https://github.com/grailbio/bazel-compilation-database
# install bazel-compilation-database

ENV INSTALL_DIR /usr/local/lib
ARG VERSION=0.4.5
RUN    cd "${INSTALL_DIR}" \
    && curl -Lk "https://github.com/grailbio/bazel-compilation-database/archive/${VERSION}.tar.gz" | tar -xz \
    && ln -f -s "${INSTALL_DIR}/bazel-compilation-database-${VERSION}/generate.sh" /usr/local/bin/bazel-compdb

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
# https://github.com/protocolbuffers/protobuf/blob/master/src/README.md
# install latest protobuf

ARG PROTOBUF_VERSION=3.13.0

RUN apt-get install -y autoconf automake libtool curl make g++ unzip && \
    git clone --depth 1 --recursive --branch v${PROTOBUF_VERSION} https://github.com/protocolbuffers/protobuf.git && \
        cd protobuf && \
        ./autogen.sh && \
        ./configure && \
        make -j10 && \
        make install

# ============================================================
# other scripts

RUN mkdir /usr/local/share/bash-color
COPY scripts/terminfo-24bit.src /usr/local/share/bash-color/

# ********************************************************************************
#
# satge 1
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder1

# ================================================================================

# dependency of llvm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            wget \
            git \
            libcurl3-dev \
            python3-dev \
            pkg-config \
            clang \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git config --global http.sslVerify false
COPY --from=builder0 /usr/local /usr/local

# ============================================================
# Build clangd
# https://gist.github.com/jakob/929ed728c96741a119798647a32618ca

RUN git clone --depth 1 https://github.com/llvm/llvm-project.git && \
    mkdir llvm-project/build-clangd && \
    cd llvm-project/build-clangd && \
    cmake -G Ninja \
          ../llvm -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
          -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_TARGETS_TO_BUILD="X86" \
          -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
          && \
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
# satge 2
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS base

# ================================================================================
# dependency of Emacs
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
# dependency of Tensorflow
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            curl \
            wget \
            git \
            libcurl3-dev \
            libfreetype6-dev \
            libhdf5-serial-dev \
            libzmq3-dev \
            pkg-config \
            rsync \
            software-properties-common \
            sudo \
            unzip \
            zip \
            zlib1g-dev \
            openjdk-11-jdk \
            openjdk-11-jre-headless \
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
# dependency of Tensorflow-runtime

ARG LLVM_VERSION=11.0.0

       # install llvm
RUN    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}.tar.xz \
              --no-check-certificate \
    && tar -xf clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}.tar.xz \
    && cp -rf clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-${UBUNTU_VERSION}/* /usr/local/ \
    && rm  clang+llvm* -rf \
       # update gcc
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y gdb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ================================================================================
# some others
RUN apt-get update && \
    apt-get install -y \
            build-essential \
            git \
            python3-dev \
            python3-venv \
            virtualenv \
            swig \
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
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ================================================================================

COPY --from=builder1 /usr/local /usr/local

ENV SHELL "/bin/bash"

RUN ldconfig

WORKDIR /workspace
