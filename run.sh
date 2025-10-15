function work-linux-server() {
    # Assumes a ".docker" (this project) and a "workspace" folder exist in $HOME.
    # cd ~/
    # ln -s your/original/.docker/path .docker
    # ln -s your/original/workspace/path workspace

    local base="$HOME/.docker"
    declare -a volumes=(
        --volume="$(realpath "$HOME/workspace"):/workspace:cached"
        --volume="$(realpath "$base/home-work"):$HOME:delegated"
        --volume="$(realpath "$base/tmp"):/tmp:cached"
        --volume="$(realpath "$base/clash_config"):/clash_config:cached"
        --volume="/var/run/docker.sock:/var/run/docker.sock"
    )

    # List your shared dirs here (expand as needed)
    declare -a shared_dirs=(
        "/share_data"
        "/software_data"
    )
    for dir in "${shared_dirs[@]}"; do
        if [ -d "$dir" ]; then
            volumes+=(--volume="$(realpath "$dir"):$dir:ro")
        fi
    done

    mkdir -p "$base/etc"
    getent passwd >"$base/etc/passwd"
    getent group >"$base/etc/group"
    volumes+=(--volume="$base/etc/passwd:/etc/passwd:ro" --volume="$base/etc/group:/etc/group:ro")

    docker run -t \
        --privileged \
        --log-driver=none \
        --hostname="$(hostname)" \
        --name "${USER}-work-server" \
        --detach-keys "ctrl-^,ctrl-@" \
        "${volumes[@]}" \
        --env-file "$base/home-work/.ssh/vpn.cfg" \
        --restart=always --detach \
        mattlu/work-dev:latest

}

function work-linux-cuda-server() {
    # Assumes a ".docker" (this project) and a "workspace" folder exist in $HOME.
    # cd ~/
    # ln -s your/original/.docker/path .docker
    # ln -s your/original/workspace/path workspace

    local base="$HOME/.docker"
    declare -a volumes=(
        --volume="$(realpath "$HOME/workspace"):/workspace:cached"
        --volume="$(realpath "$base/home-work"):/home/$(whoami):delegated"
        --volume="$(realpath "$base/tmp"):/tmp:cached"
        --volume="$(realpath "$base/clash_config"):/clash_config:cached"
        --volume="/var/run/docker.sock:/var/run/docker.sock"
    )

    # List your shared dirs here (expand as needed)
    declare -a shared_dirs=(
        "/share_data"
        "/software_data"
        "/data"
        "/zjshare_data"
        "/softhome"
        "/share"
        "/data_gpu"
    )
    for dir in "${shared_dirs[@]}"; do
        if [ -d "$dir" ]; then
            volumes+=(--volume="$(realpath "$dir"):$dir")
        fi
    done

    mkdir -p "$base/etc"
    # Use awk to find the current user's line and replace the home directory (field 6).
    getent passwd | awk -F: -v u="$(whoami)" 'BEGIN{OFS=FS} $1==u{$6="/home/"u}1' >"$base/etc/passwd"
    getent group >"$base/etc/group"
    volumes+=(--volume="$base/etc/passwd:/etc/passwd:ro" --volume="$base/etc/group:/etc/group:ro")

    docker run -t \
        --privileged \
        --gpus all \
        --log-driver=none \
        --hostname="$(hostname)" \
        --name "${USER}-work-cuda-server" \
        --detach-keys "ctrl-^,ctrl-@" \
        "${volumes[@]}" \
        --env-file "$base/home-work/.ssh/vpn.cfg" \
        --restart=always --detach \
        mattlu/work-cuda-dev:cuda12.6-ubuntu22.04

}

function work-linux-server-exec() {
    docker exec -ti --user ${UID} \
        --detach-keys "ctrl-^,ctrl-@" \
        "${USER}"-work-server /bin/bash

}

function add-network() {
    docker network create --driver bridge man.lu-net
}
