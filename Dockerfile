# --- Stage 0: Grab execstack from Ubuntu (more stable repo) ---
FROM ubuntu:22.04 AS tool-provider
RUN apt-get update && apt-get install -y execstack


# --- Stage 1: Builder ---
FROM julia:1.11.0 AS builder

WORKDIR /app

# Set a global depot path
ENV JULIA_DEPOT_PATH=/opt/julia_depot
RUN mkdir -p $JULIA_DEPOT_PATH

# Copy Julia files and instantiate the environment
COPY Project.toml Manifest.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# --- Stage 2: Final Image --- Use Miniconda as the base
FROM continuumio/miniconda3


# Set the working directory
WORKDIR /app

# Install system dependencies (Removed prelink)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
    
# Copy the execstack binary and its dependency from the Ubuntu provider
# In Ubuntu, the paths are standard
COPY --from=tool-provider /usr/bin/execstack /usr/bin/execstack
COPY --from=tool-provider /usr/lib/x86_64-linux-gnu/libelf.so.1 /usr/lib/x86_64-linux-gnu/libelf.so.1

# Run ldconfig to ensure the copied libelf is recognized
RUN ldconfig

# Copy Julia binaries and precompiled packages from builder
COPY --from=builder /usr/local/julia /usr/local/julia
COPY --from=builder /opt/julia_depot /opt/julia_depot

# Create a symlink so 'julia' is globally accessible
RUN ln -s /usr/local/julia/bin/julia /usr/local/bin/julia


# Fix the Execstack issue using the borrowed binary
RUN /usr/bin/execstack -c /usr/local/julia/lib/julia/libopenlibm.so

# Copy ONLY the environment file
COPY environment.yml .

# Create the conda environment
RUN conda env update -f environment.yml && \
    conda clean -afy

#RUN ln -s /opt/conda/envs/ap-env/bin/x86_64-conda-linux-gnu-gcc /opt/conda/envs/ap-env/bin/gcc && \
#    ln -s /opt/conda/envs/ap-env/bin/x86_64-conda-linux-gnu-g++ /opt/conda/envs/ap-env/bin/g++

# Set the PATH so the container sees the environment's tools first
ENV JULIA_DEPOT_PATH="~/.julia:/opt/julia_depot"
ENV PATH="/opt/conda/envs/ap-env/bin:${PATH}"
ENV JULIA_PROJECT="/app"



# This tells the container to always use the fenicsx-env
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "ap-env"]
