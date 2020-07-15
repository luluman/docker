ARG UBUNTU_VERSION=18.04

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
# dependcy of Tensorflow
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            curl \
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
            openjdk-8-jdk \
            openjdk-8-jre-headless \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

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

RUN apt-get update && \
    apt-get install -y \
            build-essential \
            curl \
            git \
            wget \
            openjdk-8-jdk \
            python3-dev \
            virtualenv \
            swig \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip --no-cache-dir install \
    Pillow \
    h5py \
    keras_preprocessing \
    matplotlib \
    mock \
    'numpy<1.19.0' \
    scipy \
    sklearn \
    pandas \
    future \
    portpicker \
    enum34
# ================================================================================

COPY --from=0 .emacs.d /root/.emacs.d
COPY --from=0 .local /usr/local

WORKDIR /workspace
