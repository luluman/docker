function work_1()
{
  docker run --rm --name work-man.lu \
         -v ~/Documents/workspace:/workspace \
         -v ~/Documents/install-linux:/local_install \
         -v ~/Documents/package-linux:/local_package \
         -ti work/man.lu:0.1
}

function test_1()
{
  local UID=$(id -u)
  local GID=$(id -g)
  docker run --rm -it \
         --name man.lu \
         --user $UID:$GID \
         --volume="/home/man.lu/.docker/home:/home/$USER":delegated \
         --volume="/home/man.lu/workspace:/workspace":cached \
         --volume="/etc/group:/etc/group:ro" \
         --volume="/etc/passwd:/etc/passwd:ro" \
         --volume="/etc/shadow:/etc/shadow:ro" \
         work/man.lu:1.0 /bin/bash
}
