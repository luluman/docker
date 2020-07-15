function docker_emacs_build()
{
  docker run --rm \
       -u $(id -u):$(id -g) \
       -v /home/man.lu/packages:/packages \
       -v /home/man.lu/local/16.04:/home/man.lu/local/16.04 \
       --name emacs-man.lu \
       -ti emacs/build:16.04
}

function docker_emacs_build_raw()
{
  docker run --rm \
       -u $(id -u):$(id -g) \
       -v /home/man.lu/packages:/packages \
       -v /home/man.lu/docker/16.04/usr/local:/usr/local \
       --name emacs-man.lu \
       -ti emacs/build:16.04
}

function docker_llvm_build()
{
  docker run --rm \
       -u $(id -u):$(id -g) \
       -v /home/man.lu/workspace/:/workspace \
       --name llvm-man.lu \
       -ti emacs/build:16.04
}
