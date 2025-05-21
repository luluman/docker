ARG UBUNTU_VERSION=22.04
ARG UBUNTU_NAME=jammy
ARG DEBIAN_FRONTEND="noninteractive"

# ********************************************************************************
#
# satge 0
# ********************************************************************************

FROM ubuntu:${UBUNTU_VERSION} AS builder0
ARG DEBIAN_FRONTEND
ARG UBUNTU_NAME

#  tailscale
RUN apt-get update \
    && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gpg-agent \
    software-properties-common && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_NAME}.gpg | apt-key add - && \
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
    -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd

# ==========================================================
# install clash
RUN curl -L https://downloads.clash.wiki/ClashPremium/clash-linux-amd64-v3-2023.08.17.gz | gunzip -c - > /usr/local/bin/clash \
    && chmod +x /usr/local/bin/clash


ENV SHELL="/bin/bash"

RUN ldconfig

# start SSH server
COPY scripts/start.sh /usr/bin/start.sh
RUN chmod +x /usr/bin/start.sh

CMD "start.sh"

WORKDIR /workspace
