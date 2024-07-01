function work-linux-server() {
    # Assumes a ".docker" (this project) and a "workspace" folder exist in $HOME.
    # cd ~/
    # ln -s your/original/.docker/path .docker
    # ln -s your/original/workspace/path workspace
    local home=$(realpath ~/.docker/home-work)
    local workspace=$(realpath ~/workspace)
    local tmp=$(realpath ~/.docker/tmp)
    docker run -t \
        --privileged \
        --log-driver=none \
        --hostname=$(hostname) \
        --name ${USER}-work-server \
        --detach-keys "ctrl-^,ctrl-@" \
        --volume="${home}:${HOME}":delegated \
        --volume="${workspace}:/workspace":cached \
        --volume="${tmp}:/tmp":cached \
        --volume="/etc/group:/etc/group:ro" \
        --volume="/etc/passwd:/etc/passwd:ro" \
        --volume="/etc/shadow:/etc/shadow:ro" \
        --env-file ${home}/.ssh/vpn.cfg \
        --detach \
        mattlu/work-dev:latest
}

function work-linux-server-exec() {
    docker exec -ti --user ${UID} \
        --detach-keys "ctrl-^,ctrl-@" \
        ${USER}-work-server /bin/bash

}

function add-network() {
    docker network create --driver bridge man.lu-net
}
