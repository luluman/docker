#!/bin/bash

TAILSCALE_AUTH_KEY=
EXIT_NODE_NAME=
SOCKS_NODE_NAME=

set -x

# Installs Docker Engine and associated plugins on Debian-based systems.
install_docker() {
    local keyring_path="/etc/apt/keyrings/docker.asc"

    # Prepare system for Docker installation
    apt-get update
    apt-get install -y ca-certificates curl

    # Add Docker's official GPG key to the keyring
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o "$keyring_path"
    chmod a+r "$keyring_path"

    # Determine the OS codename for the appropriate repository suite
    local os_codename
    os_codename=$(. /etc/os-release && echo "$VERSION_CODENAME")

    # Add the Docker repository to Apt sources
    tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $os_codename
Components: stable
Signed-By: $keyring_path
EOF

    # Update package index and install Docker components
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Initializes the environment by installing Docker and pulling required images.
init_environment() {
    # Install Docker if it is not already available on this system.
    if ! command -v docker &>/dev/null; then
        install_docker
    fi

    docker pull mattlu/exit-node
    docker pull mattlu/socks-node
}

# Removes existing Tailscale containers to prevent conflicts.
cleanup_containers() {
    docker container rm -f exit-node socks-node
}

# Starts a Tailscale exit node container.
run_exit_node() {
    local node_name="$1"
    docker run -d --restart always \
        --name exit-node \
        --log-driver=none \
        --env TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY}" \
        --hostname="${node_name}" \
        mattlu/exit-node
}

# Starts a Tailscale SOCKS proxy node container.
run_socks_node() {
    local node_name="$1"
    docker run -d --restart always \
        --name socks-node \
        --env TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY}" \
        --hostname="${node_name}" \
        mattlu/socks-node
}

# Main execution
init_environment
cleanup_containers

run_exit_node ${EXIT_NODE_NAME}
run_socks_node ${SOCKS_NODE_NAME}
