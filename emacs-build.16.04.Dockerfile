ARG UBUNTU_VERSION=16.04

FROM ubuntu:${UBUNTU_VERSION} AS base

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