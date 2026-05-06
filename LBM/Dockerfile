# STAGE 1: The Builder
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install only what is needed for compilation
RUN apt-get update && apt-get install -y \
    build-essential cmake git python3 python3-dev python3-pip \
    libboost-all-dev libfftw3-dev libhdf5-dev libopenmpi-dev \
    && rm -rf /var/lib/apt/lists/*

# Pin NumPy for binary compatibility
RUN pip3 install --upgrade "numpy<2" cython

# Build ESPResSo
WORKDIR /opt
RUN git clone --depth 1 --branch 4.2.2 https://github.com/espressomd/espresso.git
WORKDIR /opt/espresso/build
RUN cmake .. \
    -DWITH_PYTHON=ON \
    -DWITH_CUDA=ON \
    -DWITH_HDF5=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) \
    && make install

# STAGE 2: The Final Runtime (Optimized)
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime libraries (no compilers)
RUN apt-get update && apt-get install -y \
    python3 python3-pip openmpi-bin \
    libfftw3-3 libhdf5-103 libboost-serialization1.74.0 \
    libboost-mpi1.74.0 libboost-filesystem1.74.0 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled ESPResSo from the builder stage
COPY --from=builder /usr/local /usr/local

# Install final Python dependencies
RUN pip3 install --upgrade "numpy<2" && \
    pip3 install scipy h5py matplotlib tqdm pandas

# Set environment paths
ENV PYTHONPATH="/usr/local/lib/python3.10/dist-packages:${PYTHONPATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

WORKDIR /workspace
CMD ["/bin/bash"]
