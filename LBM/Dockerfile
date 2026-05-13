FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
# Added: gcc-10 and g++-10 to bypass the GCC 11/CUDA conflict
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-10 \
    g++-10 \
    cmake \
    git \
    wget \
    python3 \
    python3-dev \
    python3-pip \
    python3-numpy \
    cython3 \
    libboost-all-dev \
    openmpi-bin \
    libopenmpi-dev \
    libfftw3-dev \
    libhdf5-dev \
    libhdf5-openmpi-dev \
    nvidia-cuda-toolkit \
    && rm -rf /var/lib/apt/lists/*

# Install Python modules
RUN pip3 install --upgrade "numpy<2" && \
    pip3 install scipy h5py matplotlib tqdm pandas

# Clone ESPResSo 4.2.2
WORKDIR /opt
RUN git clone --branch 4.2.2 https://github.com/espressomd/espresso.git

# Build ESPResSo
WORKDIR /opt/espresso/build
# Explicitly set C and CXX compilers to version 10
RUN cmake .. \
    -DCMAKE_C_COMPILER=gcc-10 \
    -DCMAKE_CXX_COMPILER=g++-10 \
    -DWITH_PYTHON=ON \
    -DWITH_CUDA=ON \
    -DWITH_HDF5=ON \
    -DCUDA_TOOLKIT_ROOT_DIR=/usr/lib/nvidia-cuda-toolkit \
    -DPYTHON_EXECUTABLE=$(which python3) \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) \
    && make install

# Path configuration for Python 3.10
ENV PYTHONPATH="/usr/local/lib/python3.10/dist-packages"

WORKDIR /workspace
CMD ["/bin/bash"]
