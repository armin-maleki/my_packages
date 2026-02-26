# --- Stage 0: Grab execstack from Ubuntu ---
FROM ubuntu:22.04 AS tool-provider
RUN apt-get update && apt-get install -y execstack

# --- Stage 1: Builder ---
FROM julia:1.11.0 AS builder

WORKDIR /app

# 1. Bring in execstack from Ubuntu
COPY --from=tool-provider /usr/bin/execstack /usr/bin/execstack
COPY --from=tool-provider /usr/lib/x86_64-linux-gnu/libelf.so.1 /usr/lib/x86_64-linux-gnu/libelf.so.1

# 2. Link libelf and patch the Julia library DURING the build stage
RUN ldconfig && execstack -c /usr/local/julia/lib/julia/libopenlibm.so

# 3. Set depot path and precompile
ENV JULIA_DEPOT_PATH=/opt/julia_depot
RUN mkdir -p $JULIA_DEPOT_PATH
COPY Project.toml Manifest.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# 4. Aggressively clean up Julia caches, registries, and docs to save space
RUN rm -rf /opt/julia_depot/registries \
    && rm -rf /opt/julia_depot/logs \
    && rm -rf /usr/local/julia/share/doc \
    && rm -rf /usr/local/julia/share/julia/test

# --- Stage 2: Final Image --- 
FROM continuumio/miniconda3:latest

WORKDIR /app

# Copy ONLY the already-patched Julia binaries and the clean depot from builder
# No execstack or libelf makes it into this final stage!
COPY --from=builder /usr/local/julia /usr/local/julia
COPY --from=builder /opt/julia_depot /opt/julia_depot

# Symlink Julia
RUN ln -s /usr/local/julia/bin/julia /usr/local/bin/julia

# Copy ONLY the environment file
COPY environment.yml .

# Create the conda environment and clean cache in the same step
RUN conda env update -f environment.yml && \
    conda clean -afy

# Set paths so the container sees the environment's tools first
ENV JULIA_DEPOT_PATH="~/.julia:/opt/julia_depot"
ENV PATH="/opt/conda/envs/ap-env/bin:${PATH}"
ENV JULIA_PROJECT="/app"

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "ap-env"]
