function work-linux-server() {
    # Assumes a ".docker" (this project) and a "workspace" folder exist in $HOME.
    # cd ~/
    # ln -s your/original/.docker/path .docker
    # ln -s your/original/workspace/path workspace

    local home=$(realpath ~/.docker/home-work)
    local workspace=$(realpath ~/workspace)
    local tmp=$(realpath ~/.docker/tmp)
    local opt=$(realpath ~/.docker/opt)

    local dirs=("/develop01" "/data01")
    local share=""

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            share="$dir"
            echo "Directory $dir exists. Binding to container and starting Docker."
            break
        fi
    done

    if [ -z "$share" ]; then
        echo "No shared directory found. Exiting."
        return 1
    fi

    docker run -t \
        --privileged \
        --log-driver=none \
        --hostname=$(hostname) \
        --name ${USER}-work-server \
        --detach-keys "ctrl-^,ctrl-@" \
        --volume="${home}:${HOME}":delegated \
        --volume="${workspace}:/workspace":cached \
        --volume="${tmp}:/tmp":cached \
        --volume="${opt}:/opt":cached \
        --volume="${share}:${share}:ro" \
        --volume="/etc/group:/etc/group:ro" \
        --volume="/etc/passwd:/etc/passwd:ro" \
        --volume="/etc/shadow:/etc/shadow:ro" \
        --volume=/var/run/docker.sock:/var/run/docker.sock \
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
