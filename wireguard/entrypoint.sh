#!/bin/sh
set -e

WG_CONF="/etc/wireguard/wg0.conf"
CLIENT_CONF="/etc/wireguard/client.conf"

# Use user-provided WG_PORT if set; otherwise pick a random port (20000-60000)
PORT="${WG_PORT:-$(shuf -i 20000-60000 -n 1)}"

# Ensure /dev/net/tun and the UAPI socket directory exist for gotatun
mkdir -p /dev/net /var/run/wireguard /etc/wireguard
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi
chmod 700 /etc/wireguard

if [ ! -f "$WG_CONF" ]; then
    echo "Generating ephemeral WireGuard keys on UDP port ${PORT}..."
    umask 077
    SERVER_PRIV=$(wg genkey)
    SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)
    CLIENT_PRIV=$(wg genkey)
    CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
    PSK=$(wg genpsk)

    # Auto-detect public IPv6 using AAAA-only endpoints (or use SERVER_ENDPOINT if provided)
    PUBLIC_IP="${SERVER_ENDPOINT:-$(wget -qO- -T 5 http://api6.ipify.org || wget -qO- -T 5 http://v6.ident.me || echo "YOUR_SERVER_PUBLIC_IPV6")}"

    # Automatically enclose raw IPv6 addresses in square brackets [IPv6] for WireGuard
    case "$PUBLIC_IP" in
    \[*\]) ENDPOINT_HOST="$PUBLIC_IP" ;;
    *:*) ENDPOINT_HOST="[${PUBLIC_IP}]" ;;
    *) ENDPOINT_HOST="$PUBLIC_IP" ;;
    esac

    cat <<SERVER_EOF >"$WG_CONF"
[Interface]
ListenPort = ${PORT}
PrivateKey = ${SERVER_PRIV}

[Peer]
PublicKey = ${CLIENT_PUB}
PresharedKey = ${PSK}
AllowedIPs = 10.13.13.2/32, fd42:42:42::2/128
SERVER_EOF

    cat <<CLIENT_EOF >"$CLIENT_CONF"
[Interface]
PrivateKey = ${CLIENT_PRIV}
Address = 10.13.13.2/32, fd42:42:42::2/128
DNS = 2606:4700:4700::1111, 2606:4700:4700::1001, 1.1.1.1, 1.0.0.1

[Peer]
PublicKey = ${SERVER_PUB}
PresharedKey = ${PSK}
Endpoint = ${ENDPOINT_HOST}:${PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
CLIENT_EOF
fi

# Start gotatun userspace daemon and configure interface directly
echo "Starting gotatun userspace interface wg0 on UDP port ${PORT}..."
WG_SUDO=1 gotatun wg0

wg setconf wg0 "$WG_CONF"
ip -4 addr add 10.13.13.1/24 dev wg0
ip -6 addr add fd42:42:42::1/64 dev wg0
ip link set mtu 1420 up dev wg0

# Enable Dual-Stack IPv4 + IPv6 Exit Node NAT Masquerading
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

ip6tables -A FORWARD -i wg0 -j ACCEPT
ip6tables -A FORWARD -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

cleanup() {
    echo "Tearing down wg0 interface and NAT rules..."
    ip link del dev wg0 2>/dev/null || true
    exit 0
}
trap cleanup TERM INT QUIT

echo ""
echo "=================================================================="
echo "   WIREGUARD EXIT NODE READY (IPV6 ENDPOINT: ${ENDPOINT_HOST}:${PORT})"
echo "   COPY AND PASTE THIS CONFIGURATION INTO YOUR WIREGUARD CLIENT   "
echo "=================================================================="
cat "$CLIENT_CONF"
echo "=================================================================="
echo ""

# Sleep indefinitely while waiting for container stop signals
while :; do
    sleep 3600 &
    wait $!
done
