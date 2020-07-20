function work-macos()
{
  docker run --rm --name work-man.lu \
         -v ~/Documents/workspace:/workspace \
         -v ~/Documents/install-linux:/local_install \
         -v ~/Documents/package-linux:/local_package \
         -ti work/man.lu:0.1
}

function work-linux()
{
  local UID=$(id -u)
  local GID=$(id -g)
  local home=$(realpath ~/.docker/home)
  local workspace=$(realpath ~/workspace)
  docker run --rm -it \
         --name ${USER}-work \
         --user $UID:$GID \
         --detach-keys "ctrl-^,ctrl-@" \
         --volume="${home}:/home/$USER":delegated \
         --volume="${workspace}:/workspace":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
	 --add-host=gerrit.ai.bitmaincorp.vip:10.128.0.97 \
         work/man.lu:1.0 /bin/bash
}
