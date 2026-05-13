FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
# Added: libhdf5-dev for checkpointing/H5MD, and openblas for math performance
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
    && rm -rf /var/lib/apt/lists/*

# Install Python modules
# We pin numpy<2 for binary compatibility with ESPResSo 4.2.2
# Added: tqdm, pandas, and h5py (required for checkpointing/observables)
RUN pip3 install --upgrade "numpy<2" && \
    pip3 install scipy h5py matplotlib tqdm pandas

# Clone ESPResSo 4.2.2
WORKDIR /opt
RUN git clone --branch 4.2.2 https://github.com/espressomd/espresso.git

# Build ESPResSo
WORKDIR /opt/espresso/build
RUN cmake .. \
    -DWITH_PYTHON=ON \
    -DWITH_HDF5=ON \
    -DPYTHON_EXECUTABLE=$(which python3) \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) \
    && make install

# Path configuration for Python 3.10
ENV PYTHONPATH="/usr/local/lib/python3.10/dist-packages:${PYTHONPATH}"

WORKDIR /workspace
CMD ["/bin/bash"]
