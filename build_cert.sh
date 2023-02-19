#!/bin/ash

# https://docs.joshuatz.com/cheatsheets/security/self-signed-ssl-certs/

mkdir -p "$DERP_CERTS"
openssl req \
        -newkey rsa:4096 -nodes -keyout "$DERP_CERTS/${DERP_DOMAIN}.key" \
        -x509 -sha256 -days 365 -out "$DERP_CERTS/${DERP_DOMAIN}.crt" \
        -subj "/C=US/ST=WA/L=SEATTLE/O=MyCompany/OU=MyDivision/CN=${DERP_DOMAIN}" \
        -addext "subjectAltName = DNS:${DERP_DOMAIN}, DNS:localhost, DNS:127.0.0.1, IP:${DERP_HOST}"

trap 'kill -TERM $PID' TERM INT
echo "Starting Tailscale daemon"
# -state=mem: will logout and remove ephemeral node from network immediately after ending.
tailscaled --tun=userspace-networking -no-logs-no-support --state=${TAILSCALE_STATE_ARG} &
PID=$!
until tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="${TAILSCALE_HOSTNAME}"; do
    sleep 0.1
done
tailscale status
