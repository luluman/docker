ARG UBUNTU_VERSION=18.04
# ********************************************************************************
#
# satge 0
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS base

# ================================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            build-essential \
            curl \
            pkg-config \
            software-properties-common \
            sudo \
            iputils-ping \
            openssh-client \
            && \
    add-apt-repository -y ppa:dwmw2/openconnect && \
    apt-get update && \
    apt-get install -y openconnect && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV SHELL "/bin/bash"
