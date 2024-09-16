FROM tailscale/tailscale:stable

# RUN echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf && \
# echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf

COPY scripts/exit-node.sh /usr/bin/start.sh
RUN chmod +x /usr/bin/start.sh
CMD "start.sh"
