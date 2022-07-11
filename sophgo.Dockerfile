FROM ubuntu:18.04 AS builder
ARG DEBIAN_FRONTEND=nointeractive
ENV TZ=Asia/Shanghai
ENV CMAKE_VERSION 3.20.0

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates && \
    echo '[global]' > /etc/pip.conf && \
    echo 'timeout = 60' >> /etc/pip.conf && \
    echo 'index-url = https://pypi.doubanio.com/simple' >> /etc/pip.conf && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y build-essential git vim \
        libhdf5-dev libopenblas-dev \
        libboost-dev libboost-filesystem-dev libboost-system-dev \
        libboost-regex-dev libboost-thread-dev \
        libncurses5-dev \
        python3.7-dev \
        python3-distutils \
				curl wget \
        libnuma1 libatlas-base-dev \
        unzip vim \
        graphviz \
        gdb && \
		apt-get clean && \
		update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 0 && \
	  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
		python3.7 get-pip.py && \
		wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-Linux-x86_64.sh \
      --no-check-certificate -q -O /tmp/cmake-install.sh && \
      chmod u+x /tmp/cmake-install.sh && \
      /tmp/cmake-install.sh --skip-license --prefix=/usr/local && \
			rm /tmp/cmake-install.sh && \ 
		git clone https://github.com/google/glog.git && \
			cd glog && git checkout v0.5.0 && mkdir -p build && cd build && cmake ../ && make -j 4 && make install &&\
	  pip3 install \
			argcomplete \
			Cython \
			decorator \
			enum34 \
			gitpython \
			ipython \
			jedi \
			Jinja2 \
			jupyterlab \
			kaleido \
			leveldb \
			lmdb \
			matplotlib \
			networkx \
			nose \
			numpy \
			mxnet==1.8.0 \
			onnx==1.7.0 \
			onnxruntime==1.6.0 \
			onnx-simplifier \
			opencv-contrib-python \
			opencv-python \
			opencv-python-headless \
			packaging \
			pandas \
			paramiko \
			Pillow \
			plotly \
			ply \
			protobuf \
			pybind11[global] \
			pycocotools \
			python-dateutil \
			python-gflags \
			pyyaml \
			scikit-image \
			scipy \
			six \
			tensorflow-cpu \
			termcolor \
			tf2onnx \
			tqdm \
			wheel && \
		pip3 install torch==1.8.2 torchvision==0.9.2 torchaudio===0.8.2 --extra-index-url https://download.pytorch.org/whl/lts/1.8/cpu &&  \
		rm -rf ~/.cache/pip/*

#COPY --from=builder /usr/local /usr/local

WORKDIR /workspace
