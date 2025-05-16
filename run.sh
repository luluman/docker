function work-linux-server() {
    # Assumes a ".docker" (this project) and a "workspace" folder exist in $HOME.
    # cd ~/
    # ln -s your/original/.docker/path .docker
    # ln -s your/original/workspace/path workspace

    local home=$(realpath ~/.docker/home-work)
    local workspace=$(realpath ~/workspace)
    local tmp=$(realpath ~/.docker/tmp)
    local opt=$(realpath ~/.docker/opt)

    local share_data=$(realpath /share_data)
    local software_data=$(realpath /software_data)

    getent passwd &> ~/.docker/etc/passwd
    getent group &> ~/.docker/etc/group

    local group_file=$(realpath ~/.docker/etc/group)
    local passwd_file=$(realpath ~/.docker/etc/passwd)

    local container_name=${USER}-work-server

    docker run -t \
        --privileged \
        --log-driver=none \
        --hostname=$(hostname) \
        --name ${container_name} \
        --detach-keys "ctrl-^,ctrl-@" \
        --volume="${home}:${HOME}":delegated \
        --volume="${workspace}:/workspace":cached \
        --volume="${tmp}:/tmp":cached \
        --volume="${opt}:/opt":cached \
        --volume="${share_data}":/share_data:ro \
        --volume="${software_data}":/software_data:ro \
        --volume="{group_file}:/etc/group:ro" \
        --volume="{passwd_file}:/etc/passwd:ro" \
        --volume=/var/run/docker.sock:/var/run/docker.sock \
        --env-file ${home}/.ssh/vpn.cfg \
        --restart=always \
        --detach \
        mattlu/work-dev:latest

    # copy driver
    local latest_drv=$(find /usr/local -type d -name 'houmo_drv*' -not -empty | sort -r | head -n 1)
    if [[ "${latest_drv}" != *houmo_drv* ]]; then
        echo -e "\e[31mcannot find driver in /usr/local\e[0m"
    else
        echo -e "\e[31musing latest driver ${latest_drv}\e[0m"
        docker cp ${latest_drv} ${container_name}:/usr/local/houmo-sdk
    fi
}

function work-linux-server-exec() {
    docker exec -ti --user ${UID} \
        --detach-keys "ctrl-^,ctrl-@" \
        ${USER}-work-server /bin/bash

}

function add-network() {
    docker network create --driver bridge man.lu-net
}
