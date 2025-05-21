#!/usr/bin/env bash
set -e

# generate host keys if not present
ssh-keygen -A
# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e &

echo "Start clash"
exec clash -f /clash_config/clash_config.yaml -d /clash_config/ &

trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled -no-logs-no-support --state="${TAILSCALE_STATE_ARG}" &
PID=$!
LOGIN_SERVER_ARG=""
if [ -n "${TAILSCALE_SERVER}" ]; then
  LOGIN_SERVER_ARG="--login-server=${TAILSCALE_SERVER}"
fi

until tailscale up "${LOGIN_SERVER_ARG}" --authkey="${TAILSCALE_AUTH_KEY}" --hostname="$(hostname)"; do
    sleep 0.1
done

tailscale status

wait ${PID}
wait ${PID}
