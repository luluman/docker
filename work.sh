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
         work/man.lu:1.0 /bin/bash
}

function work-linux()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ~/.docker/home)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  docker run -it \
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
         mattlu/work-dev:latest /bin/bash
}

function explor-linux()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ~/.docker/home)
  local workspace=$(realpath ~/workspace)
  local data=$(realpath /data)
  docker run -it \
         --privileged \
         --name ${USER}-explor \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --network man.lu-net \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="${data}:/data":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         mattlu/explor-dev:latest /bin/bash
}

function work-linux-attach()
{
  docker attach \
         ${USER}-work \
         --detach-keys "ctrl-^,ctrl-@"
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

function add-network()
{
  docker network create --driver bridge man.lu-net
}
