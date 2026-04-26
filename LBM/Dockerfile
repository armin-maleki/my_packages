FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required build tools and dependencies
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

# Install optional but recommended Python packages
RUN pip3 install scipy h5py matplotlib

# Clone ESPResSo version 4.2.2
WORKDIR /opt
RUN git clone --branch 4.2.2 https://github.com/espressomd/espresso.git

# Configure and build ESPResSo
WORKDIR /opt/espresso/build
RUN cmake .. \
    -DWITH_PYTHON=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) \
    && make install

# Set the Python path so ESPResSo can be imported globally
# Note: Ubuntu 22.04 uses python3.10
ENV PYTHONPATH="/usr/local/lib/python3.10/dist-packages:${PYTHONPATH}"

# Set default working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
