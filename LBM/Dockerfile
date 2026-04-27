FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required build tools and dependencies
# We keep python3-numpy here as a system dependency for the build headers
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
    libhdf5-openmpi-dev \
    && rm -rf /var/lib/apt/lists/*

# CRITICAL FIX: Pin NumPy to the 1.x series BEFORE building ESPResSo
# This ensures that when ESPResSo compiles its Cython/C++ extensions,
# it uses the binary interface compatible with NumPy 1.x.
RUN pip3 install --upgrade "numpy<2"
RUN pip3 install scipy h5py matplotlib

# Clone ESPResSo version 4.2.2
WORKDIR /opt
RUN git clone --branch 4.2.2 https://github.com/espressomd/espresso.git

# Configure and build ESPResSo
WORKDIR /opt/espresso/build
RUN cmake .. \
    -DWITH_PYTHON=ON \
    -DPYTHON_EXECUTABLE=$(which python3) \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) \
    && make install

# Path Fix: On Ubuntu 22.04, the 'make install' usually places the 
# module in /usr/local/lib/python3.10/dist-packages.
ENV PYTHONPATH="/usr/local/lib/python3.10/dist-packages:${PYTHONPATH}"

WORKDIR /workspace

CMD ["/bin/bash"]
