function work-macos()
{
  local home=~/Documents/docker/home
  local workspace=~/Documents/workspace
  docker run --rm -ti \
         --name ${USER}-work \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/root":delegated \
         --volume="${workspace}:/workspace":cached \
         --add-host=gerrit.ai.bitmaincorp.vip:10.128.0.97 \
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
  docker run -t \
         --privileged \
         --name ${USER}-work \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --network man.lu-net \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --add-host=gerrit.ai.bitmaincorp.vip:10.128.0.97 \
         --detach \
         mattlu/work-dev:latest /bin/bash
}

function explore-linux()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ~/.docker/home-explore)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  docker run -t \
         --privileged \
         --name ${USER}-explore \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --network man.lu-net \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         --add-host=gerrit.ai.bitmaincorp.vip:10.128.0.97 \
         --add-host=gitlab.bitmaincorp.vip:10.128.1.4 \
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
