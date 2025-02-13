#!/bin/ash
trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
# https://tailscale.com/kb/1112/userspace-networking
tailscaled --tun=userspace-networking \
           --socks5-server=100.64.0.0/10@:1055 \
           --outbound-http-proxy-listen=100.64.0.0/10@:1055 \
           -no-logs-no-support &
PID=$!
# https://github.com/tailscale/tailscale/issues/5412
until tailscale up \
    --authkey="${TAILSCALE_AUTH_KEY}" \
    --hostname="${TAILSCALE_HOSTNAME}"; do
    sleep 0.1
done
tailscale status
wait ${PID}
wait ${PID}
