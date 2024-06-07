#!/usr/bin/env bash
set -e

# generate host keys if not present
ssh-keygen -A
# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e &

echo "Download config file and start clash"
exec `/opt/vpn-config.py "${CLASH_SUBSCRIPTION_URL}"` &

trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled -no-logs-no-support --state=${TAILSCALE_STATE_ARG} &
PID=$!
until tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="$(hostname)"; do
    sleep 0.1
done
tailscale status
wait ${PID}
wait ${PID}
