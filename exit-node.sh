#!/bin/ash
trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled --tun=userspace-networking -no-logs-no-support --state=${TAILSCALE_STATE_ARG} &
PID=$!
until tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="${TAILSCALE_HOSTNAME}" --advertise-exit-node; do
    sleep 0.1
done
tailscale status
wait ${PID}
wait ${PID}
