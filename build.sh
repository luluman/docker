docker build -t emacs/build:16.04 -f ./emacs-build.16.04.Dockerfile .
docker build -t emacs/build:18.04 -f ./emacs-build.18.04.Dockerfile .

docker build -t expt/man.lu:0.1 -f ./experiment.Dockerfile .

docker build -t work/man.lu:0.1 -f ./work.Dockerfile .
