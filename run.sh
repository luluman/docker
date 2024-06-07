function work-linux-server()
{
  local home=$(realpath ./home-work)
  local workspace=$(realpath ~/workspace)
  local bjnfsdata01=$(realpath /bjnfsdata01)
  local tmp=$(realpath ./tmp)
  docker run -t \
         --privileged \
         --log-driver=none \
         --hostname=$(hostname) \
         --name ${USER}-work-server \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${bjnfsdata01}:/bjnfsdata01":cached \
         --volume="${tmp}:/tmp":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --volume=/var/run/docker.sock:/var/run/docker.sock \
         --env-file ${home}/.ssh/vpn.cfg \
         --detach \
         mattlu/work-dev:latest
}

function work-macos()
{
  local home=~/Documents/docker/home
  local workspace=~/Documents/workspace
  docker run --rm -ti \
         --name ${USER}-work \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/root":delegated \
         --volume="${workspace}:/workspace":cached \
         --detach \
         mattlu/work-dev:latest
}

function work-linux()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ./home-work)
  local workspace=$(realpath ~/workspace)
  local bjnfsdata01=$(realpath /bjnfsdata01)
  local tmp=$(realpath ./tmp)
  docker run -t \
         --privileged \
         --log-driver=none \
         --name ${USER}-work \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${bjnfsdata01}:/bjnfsdata01":cached \
         --volume="${tmp}:/tmp":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --volume=/var/run/docker.sock:/var/run/docker.sock \
         --detach \
         mattlu/work-dev:latest /bin/bash
}

function work-linux-attach()
{
  docker attach \
         ${USER}-work \
         --detach-keys "ctrl-^,ctrl-@"
}

function work-linux-exec()
{
  docker exec -ti \
         --detach-keys "ctrl-^,ctrl-@" \
         ${USER}-work /bin/bash

}

function work-linux-server-exec()
{
  docker exec -ti --user ${UID} \
         --detach-keys "ctrl-^,ctrl-@" \
         ${USER}-work-server /bin/bash

}

function add-network()
{
  docker network create --driver bridge man.lu-net
}
