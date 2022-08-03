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
  docker run -t \
         --privileged \
         --name ${USER}-work \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="${share}:/share":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --detach \
         mattlu/work-dev:latest /bin/bash
}

function work-linux-16.04()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ~/.docker/home-work-16.04)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  local share=$(realpath /share)
  docker run -t \
         --privileged \
         --name ${USER}-work-18.04 \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --detach \
         mattlu/work-dev:16.04 /bin/bash
}

function explore-linux()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ~/.docker/home-explore)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  local share=$(realpath /share)
  docker run -t \
         --privileged \
         --name ${USER}-explore \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="${share}:/share":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --detach \
         mattlu/explore-dev:latest /bin/bash
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

function work-linux-exec-16.04()
{
  docker exec -ti \
         --detach-keys "ctrl-^,ctrl-@" \
         ${USER}-work-16.04 /bin/bash

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
