# --- Stage 0: Grab execstack from Ubuntu ---
FROM ubuntu:22.04 AS tool-provider
RUN apt-get update && apt-get install -y execstack

# --- Stage 1: Julia Source ---
# We use the official image just to copy the clean binaries
FROM julia:1.11.0 AS julia-source

# --- Stage 2: Builder ---
# optimization: Use the same base as final image so we can link against the real Python
FROM continuumio/miniconda3:latest AS builder

WORKDIR /app

# 1. Install system tools needed for building/patching
# (continuumio is debian-based, so apt-get works)
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy Julia from source
COPY --from=julia-source /usr/local/julia /usr/local/julia
ENV PATH="/usr/local/julia/bin:${PATH}"

# 3. Bring in execstack tools
COPY --from=tool-provider /usr/bin/execstack /usr/bin/execstack
COPY --from=tool-provider /usr/lib/x86_64-linux-gnu/libelf.so.1 /usr/lib/x86_64-linux-gnu/libelf.so.1

# 4. Patch Julia
RUN ldconfig && execstack -c /usr/local/julia/lib/julia/libopenlibm.so

# 5. Create the Conda Environment HERE in the builder
# This ensures we have the exact Python binary that Julia needs to link against
COPY environment.yml .
RUN conda env update -f environment.yml && conda clean -afy

# 6. Configure Julia to use the System Conda (Critical Optimization)
# This prevents downloading a second miniconda into /opt/julia_depot/conda
ENV PYTHON="/opt/conda/envs/ap-env/bin/python"
ENV JULIA_DEPOT_PATH=/opt/julia_depot
ENV JULIA_PROJECT=/app

# 7. Install & Precompile Julia Packages
COPY Project.toml Manifest.toml ./
RUN mkdir -p $JULIA_DEPOT_PATH && \
    julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# 8. Aggressively clean up
# We explicitly remove the julia_depot/conda folder to ensure no duplication
RUN rm -rf /opt/julia_depot/registries \
    && rm -rf /opt/julia_depot/logs \
    && rm -rf /opt/julia_depot/conda \
    && rm -rf /usr/local/julia/share/doc \
    && rm -rf /usr/local/julia/share/julia/test

# --- Stage 3: Final Image --- 
FROM continuumio/miniconda3:latest

WORKDIR /app

# 1. Copy ONLY the patched Julia binaries and the clean depot
COPY --from=builder /usr/local/julia /usr/local/julia
COPY --from=builder /opt/julia_depot /opt/julia_depot

# 2. Symlink Julia
RUN ln -s /usr/local/julia/bin/julia /usr/local/bin/julia

# 3. Re-create the Conda environment
# (We repeat this to ensure a clean layer, but it will match the builder version)
COPY environment.yml .
RUN conda env update -f environment.yml && \
    conda clean -afy

# 4. Runtime Environment Variables
ENV JULIA_DEPOT_PATH="~/.julia:/opt/julia_depot"
ENV PATH="/opt/conda/envs/ap-env/bin:${PATH}"
ENV JULIA_PROJECT="/app"
# Ensure runtime Julia uses the correct Python
ENV PYTHON="/opt/conda/envs/ap-env/bin/python"

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "ap-env"]
