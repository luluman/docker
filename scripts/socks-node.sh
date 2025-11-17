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

# Build argument list
set -- # clear "$@"
if [ -n "${TAILSCALE_SERVER}" ]; then
    set -- "$@" "--login-server=${TAILSCALE_SERVER}"
fi
set -- "$@" \
    "--authkey=${TAILSCALE_AUTH_KEY}" \
    "--hostname=${TAILSCALE_HOSTNAME}"

# "$@" expands only to real args; no empty placeholder
until tailscale up "$@"; do
    sleep 0.1
done

tailscale status
wait ${PID}
wait ${PID}
