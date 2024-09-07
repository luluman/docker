FROM alpine:latest

RUN \
    echo "**** install dependencies ****" && \
    apk add --no-cache \
    bc \
    coredns \
    grep \
    iproute2 \
    iptables \
    iptables-legacy \
    ip6tables \
    iputils \
    wireguard-tools && \
    echo "wireguard" >> /etc/modules && \
    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf && \
    echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf && \
    rm -rf \
    /tmp/*

COPY scripts/wireguard.sh /usr/bin/start.sh
RUN chmod +x /usr/bin/start.sh
CMD "start.sh"
