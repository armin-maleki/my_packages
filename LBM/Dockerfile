FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
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
# Added -DCMAKE_CUDA_STANDARD=14 to fix the GCC 11 compatibility error
RUN cmake .. \
    -DWITH_PYTHON=ON \
    -DWITH_CUDA=ON \
    -DWITH_HDF5=ON \
    -DCMAKE_CUDA_STANDARD=14 \
    -DCUDA_TOOLKIT_ROOT_DIR=/usr/lib/nvidia-cuda-toolkit \
    -DPYTHON_EXECUTABLE=$(which python3) \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) \
    && make install

# Path configuration for Python 3.10
# Note: Fixed the undefined $PYTHONPATH warning by using a clean assignment
ENV PYTHONPATH="/usr/local/lib/python3.10/dist-packages"

WORKDIR /workspace
CMD ["/bin/bash"]
