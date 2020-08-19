docker build -t emacs/build:16.04 -f ./emacs-build.16.04.Dockerfile .
docker build -t emacs/build:18.04 -f ./emacs-build.18.04.Dockerfile .
docker build -t expt/man.lu:0.1 -f ./experiment.Dockerfile .
docker build -t work/man.lu:0.1 -f ./work.Dockerfile .
docker build -t work/man.lu:1.0 -f ./work-all.Dockerfile .
--build-arg http_proxy=http://172.16.74.88:3128 --build-arg https_proxy=http://172.16.74.88:3128
docker run -it --rm --cap-add=NET_ADMIN local /bin/bash
