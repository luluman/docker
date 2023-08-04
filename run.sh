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
  local home=$(realpath ~/.docker/home-work)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  local share=$(realpath /share)
  local tmp=$(realpath ~/.docker/tmp)
  docker run -t \
         --privileged \
         --log-driver=none \
         --name ${USER}-work \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="${share}:/share":cached \
         --volume="${tmp}:/tmp":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --volume=/var/run/docker.sock:/var/run/docker.sock \
         --detach \
         mattlu/work-dev:latest /bin/bash
}

function work-linux-server()
{
  local home=$(realpath ~/.docker/home-work)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  local share=$(realpath /share)
  local tmp=$(realpath ~/.docker/tmp)
  docker run -t \
         --privileged \
         --log-driver=none \
         --name ${USER}-work-server \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="${share}:/share":cached \
         --volume="${tmp}:/tmp":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --volume=/var/run/docker.sock:/var/run/docker.sock \
         --env-file ~/.docker/home-work/.ssh/vpn.cfg \
         --detach \
         mattlu/work-dev:latest
}

function explore-linux()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ~/.docker/home-explore)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  local share=$(realpath /share)
  local tmp=$(realpath ~/.docker/tmp)
  docker run -t \
         --privileged \
         --log-driver=none \
         --name ${USER}-explore \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="${share}:/share":cached \
         --volume="${tmp}:/tmp":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --volume=/var/run/docker.sock:/var/run/docker.sock \
         --detach \
         mattlu/explore-dev:latest /bin/bash
}

function explore-linux-server()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ~/.docker/home-explore)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  local share=$(realpath /share)
  local tmp=$(realpath ~/.docker/tmp)
  docker run -t \
         --privileged \
         --log-driver=none \
         --name ${USER}-explore-server \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="${share}:/share":cached \
         --volume="${tmp}:/tmp":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --volume=/var/run/docker.sock:/var/run/docker.sock \
         --env-file ~/.docker/home-explore/.ssh/vpn.cfg \
         --detach \
         mattlu/explore-dev:latest
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

function explore-linux-attach()
{
  docker attach \
         ${USER}-explore \
         --detach-keys "ctrl-^,ctrl-@"
}

function explore-linux-exec()
{
  docker exec -ti \
         --detach-keys "ctrl-^,ctrl-@" \
         ${USER}-explore /bin/bash
}

function work-langtool-server()
{
  local ngrams=$(realpath ~/.docker/ngrams)
  docker run -d \
         --name langtool-server \
         --network man.lu-net \
         --volume="${ngrams}:/ngrams:ro" \
         --restart=unless-stopped \
         silviof/docker-languagetool
}

function plantuml-server()
{
  docker run -d \
         --name plantuml-server \
         --network man.lu-net \
         --restart=unless-stopped \
         plantuml/plantuml-server:jetty
}

function add-network()
{
  docker network create --driver bridge man.lu-net
}
