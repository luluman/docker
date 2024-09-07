#!/bin/ash
trap 'kill -TERM $PID' TERM INT
echo "Starting Wireguard"

wg-quick up wg0 &
PID=$!

wg show
wait ${PID}
wait ${PID}
