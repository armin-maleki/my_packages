# STAGE 1: The Builder (Heavy - contains compilers and dev headers)
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-dev python3-pip \
    libboost-all-dev libfftw3-dev libhdf5-openmpi-dev libopenmpi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install build-time Python requirements
RUN pip3 install --upgrade "numpy<2" cython

# Clone ESPResSo 4.2.2
WORKDIR /opt
RUN git clone --depth 1 --branch 4.2.2 https://github.com/espressomd/espresso.git

# Build ESPResSo with Parallel HDF5 and CUDA
WORKDIR /opt/espresso/build
RUN CC=mpicc CXX=mpicxx cmake .. \
    -DWITH_PYTHON=ON \
    -DWITH_CUDA=ON \
    -DWITH_HDF5=ON \
    -DHDF5_PREFER_PARALLEL=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) \
    && make install

# STAGE 2: The Final Runtime (Lightweight - contains only libraries)
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime libraries and MPI help files
RUN apt-get update && apt-get install -y \
    python3 python3-pip openmpi-bin openmpi-common \
    libfftw3-3 libhdf5-openmpi-103 libboost-serialization1.74.0 \
    libboost-mpi1.74.0 libboost-filesystem1.74.0 \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled binaries and Python site-packages from builder
COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt/espresso /opt/espresso

# Install user-facing Python modules
# We pin numpy<2 again to match the version used during ESPResSo compilation
RUN pip3 install --upgrade "numpy<2" && \
    pip3 install scipy h5py matplotlib tqdm pandas

# Set environment paths
ENV PYTHONPATH="/usr/local/lib/python3.10/dist-packages"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

WORKDIR /workspace
CMD ["/bin/bash"]
