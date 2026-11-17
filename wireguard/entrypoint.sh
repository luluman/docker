#!/bin/sh
set -e

WG_CONF="/etc/wireguard/wg0.conf"
CLIENT_CONF="/etc/wireguard/client.conf"

# Ensure /dev/net/tun and the UAPI socket directory exist for gotatun
mkdir -p /dev/net /var/run/wireguard /etc/wireguard
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi
chmod 700 /etc/wireguard

if [ ! -f "$WG_CONF" ]; then
    echo "Generating ephemeral WireGuard keys on UDP port ${WG_PORT}..."
    umask 077
    SERVER_PRIV=$(wg genkey)
    SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)
    CLIENT_PRIV=$(wg genkey)
    CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
    PSK=$(wg genpsk)

    # Auto-detect public IPv4 and IPv6
    PUBLIC_IPV4=$(wget -qO- -T 5 http://api4.ipify.org || wget -qO- -T 5 http://v4.ident.me || echo "YOUR_SERVER_PUBLIC_IPV4")
    PUBLIC_IPV6=$(wget -qO- -T 5 http://api6.ipify.org || wget -qO- -T 5 http://v6.ident.me || echo "YOUR_SERVER_PUBLIC_IPV6")

    cat <<SERVER_EOF >"$WG_CONF"
[Interface]
ListenPort = ${WG_PORT}
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
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001
MTU = 1420

[Peer]
PublicKey = ${SERVER_PUB}
PresharedKey = ${PSK}
Endpoint = ${PUBLIC_IPV4}:${WG_PORT}
# Endpoint = [${PUBLIC_IPV6}]:${WG_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
CLIENT_EOF
fi

# Start gotatun userspace daemon and configure interface directly
echo "Starting gotatun userspace interface wg0 on UDP port ${WG_PORT}..."
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
echo "   WIREGUARD DUAL-STACK EXIT NODE READY"
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
