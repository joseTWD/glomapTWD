ARG UBUNTU_VERSION=20.04
ARG NVIDIA_CUDA_VERSION=11.8.0

FROM nvidia/cuda:${NVIDIA_CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive 
ENV TZ=Europe/Madrid

ARG PYTHON_VERSION=3.10
ARG NUMBER_OF_CORES=8
ARG CUDA_ARCHITECTURES=native1
ENV CUB_VERSION=1.10.0
ENV CUB_HOME=/workspace/cub-${CUB_VERSION}

# Python installation
RUN apt update -y
RUN apt install -y unzip wget software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt -y update && \
    apt install -y python${PYTHON_VERSION}
RUN wget https://bootstrap.pypa.io/get-pip.py && python${PYTHON_VERSION} get-pip.py
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1
RUN apt install -y python${PYTHON_VERSION}-dev

# Install OpenSSL and development libraries
RUN apt-get install -y libssl-dev

# Colmap installation
WORKDIR /usr/local/src

RUN wget https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0.tar.gz && \
    tar -zxvf cmake-3.28.0.tar.gz && \
    cd cmake-3.28.0 && \
    ./bootstrap && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf cmake-3.28.0.tar.gz cmake-3.28.0

RUN apt-get update &&\
    apt install -y \
    git \
    ninja-build \
    build-essential \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libboost-test-dev \
    libflann-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libsqlite3-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libhdf5-dev \
    libblas-dev \
    liblapack-dev \
    libsuitesparse-dev \
    libopenblas-dev


# Install dependencies for Eigen3
RUN apt-get update && apt-get install -y \
    wget \
    build-essential

# Install Eigen3 from source
RUN wget http://gitlab.com/libeigen/eigen/-/archive/3.4/eigen-3.4.tar.gz && \
    tar -xvzf eigen-3.4.tar.gz && \
    cd eigen-3.4 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf eigen-3.4.tar.gz eigen-3.4

# Install Ceres.
WORKDIR /usr/local/src
RUN apt-get install -y --no-install-recommends --no-install-suggests wget && \
    wget "http://ceres-solver.org/ceres-solver-2.1.0.tar.gz" && \
    tar zxf ceres-solver-2.1.0.tar.gz && \
    mkdir ceres-build && \
    cd ceres-build && \
    cmake ../ceres-solver-2.1.0 -GNinja -DCMAKE_INSTALL_PREFIX=/usr/local && \
    ninja -j${NUMBER_OF_CORES} install

# Build and install COLMAP.
WORKDIR /usr/local/src
RUN wget https://github.com/colmap/colmap/archive/refs/tags/3.8.tar.gz && tar xzf 3.8.tar.gz
WORKDIR /usr/local/src/colmap-3.8/build
RUN cmake -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} .. -GNinja && ninja && ninja -j${NUMBER_OF_CORES} install

ENV TCNN_CUDA_ARCHITECTURES="86"


# Upgrade pip and install required Python tools
RUN pip install --upgrade pip setuptools wheel


# Clone the GLOMAP repository
WORKDIR /workspace
RUN git clone --recursive https://github.com/colmap/glomap

RUN cd glomap && mkdir build && cd build && \
    cmake -GNinja -DCMAKE_VERBOSE_MAKEFILE=ON .. && \
    ninja -j2 && ninja install


# Install pyglomap Python package

# WORKDIR /workspace/GLOMAP
# ENV PYTHONPATH=/workspace/GLOMAP/pyglomap:$PYTHONPATH