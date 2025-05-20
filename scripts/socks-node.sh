#!/bin/ash
trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
# https://tailscale.com/kb/1112/userspace-networking
tailscaled --tun=userspace-networking \
    --socks5-server=0.0.0.0:1055 \
    --outbound-http-proxy-listen=0.0.0.0:1055 \
    -no-logs-no-support &
PID=$!
# https://github.com/tailscale/tailscale/issues/5412
LOGIN_SERVER_ARG=""
if [ -n "${TAILSCALE_SERVER}" ]; then
  LOGIN_SERVER_ARG="--login-server=${TAILSCALE_SERVER}"
fi

until tailscale up "${LOGIN_SERVER_ARG}" --authkey="${TAILSCALE_AUTH_KEY}" --hostname="${TAILSCALE_HOSTNAME}"; do
  sleep 0.1
done
tailscale status
wait ${PID}
wait ${PID}
