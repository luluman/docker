#!/bin/sh
set -eu

: "${TS_AUTHKEY:?TS_AUTHKEY is required}"

log() { echo "==> $*"; }

detect_ip() {
    for url in https://api.ip.sb/ip https://ifconfig.me https://icanhazip.com https://checkip.amazonaws.com; do
        ip=$(curl -4 -fsSL -m 3 "$url" 2>/dev/null | tr -d '[:space:]') && [ -n "$ip" ] && {
            echo "$ip"
            return 0
        }
    done
    return 1
}

PUBLIC_IP="${DERP_HOST:-$(detect_ip || true)}"
: "${PUBLIC_IP:?Could not detect public IP; set DERP_HOST manually}"

CERT="${DERP_CERTS}/${DERP_DOMAIN}.crt"
KEY="${DERP_CERTS}/${DERP_DOMAIN}.key"

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
    log "Generating ECDSA P-256 certificate for ${DERP_DOMAIN} (${PUBLIC_IP})..."
    mkdir -p "$DERP_CERTS"
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -sha256 -days 3650 -nodes -keyout "$KEY" -out "$CERT" \
        -subj "/CN=${DERP_DOMAIN}" \
        -addext "subjectAltName=DNS:${DERP_DOMAIN},IP:${PUBLIC_IP}" 2>/dev/null
fi

CERT_HASH=$(openssl x509 -noout -fingerprint -sha256 -in "$CERT" | cut -d= -f2 | tr -d ':' | tr '[:upper:]' '[:lower:]')

log "Starting tailscaled..."
tailscaled --tun=userspace-networking --no-logs-no-support --state="${TS_STATE:-mem:}" &

until tailscale up \
    --authkey="$TS_AUTHKEY" \
    --hostname="${TS_HOSTNAME:-$(hostname)}" \
    ${TS_LOGIN_SERVER:+--login-server="$TS_LOGIN_SERVER"}; do
    sleep 0.5
done

cat <<EOF

================ Tailscale ACL derpMap ================
"derpMap": {
  "OmitDefaultRegions": false,
  "Regions": {
    "900": {
      "RegionID": 900,
      "RegionCode": "cn",
      "RegionName": "${TS_HOSTNAME:-cn-derp}",
      "Nodes": [
        {
          "Name": "900a",
          "RegionID": 900,
          "HostName": "${DERP_DOMAIN}",
          "IPv4": "${PUBLIC_IP}",
          "DERPPort": ${DERP_ADDR##*:},
          "CertName": "sha256-raw:${CERT_HASH}"
        }
      ]
    }
  }
}
=======================================================

EOF

log "Starting derper on ${DERP_ADDR}..."
exec derper \
    --hostname="$DERP_DOMAIN" \
    --certmode=manual \
    --certdir="$DERP_CERTS" \
    --stun="$DERP_STUN" \
    --a="$DERP_ADDR" \
    --http-port="$DERP_HTTP_PORT" \
    --verify-clients=true
