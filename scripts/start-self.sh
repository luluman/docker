#!/usr/bin/env bash
set -e

# generate host keys if not present
ssh-keygen -A
# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e &
PID=$!

echo "Start clash"
exec clash -f /opt/clash_config.yaml -d /opt/ &

trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale"

until tailscale up --login-server="${TAILSCALE_SERVER}" --authkey="${TAILSCALE_AUTH_KEY}" --hostname="$(hostname)"; do
    sleep 0.1
done

tailscale status

wait ${PID}
wait ${PID}
