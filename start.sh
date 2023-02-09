#!/usr/bin/env bash
set -ex

trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled --tun=userspace-networking -no-logs-no-support --state=${TAILSCALE_STATE_ARG} &
PID=$!
until tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="${TAILSCALE_HOSTNAME}"; do
    sleep 0.1
done
tailscale status
wait ${PID}
wait ${PID}

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -p 22
