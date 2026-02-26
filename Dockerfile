# --- Stage 0: Grab execstack from Ubuntu ---
FROM ubuntu:22.04 AS tool-provider
RUN apt-get update && apt-get install -y execstack

# --- Stage 1: Julia Source ---
FROM julia:1.11.0 AS julia-source

# --- Stage 2: Builder ---
FROM continuumio/miniconda3:latest AS builder

WORKDIR /app

# 1. Install system tools
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

# 5. Create the Conda environment FIRST
COPY environment.yml .
RUN conda env update -f environment.yml && conda clean -afy

# 6. CRITICAL: Configure Julia BEFORE Pkg.instantiate()
# This tells Conda.jl to use the system environment instead of creating its own
ENV PYTHON="/opt/conda/envs/ap-env/bin/python"
ENV CONDA_JL_CONDA_EXE="/opt/conda/bin/conda"
ENV CONDA_JL_USE_MAMBA="no"
ENV JULIA_DEPOT_PATH=/opt/julia_depot
ENV JULIA_PROJECT=/app

# 7. Initialize Conda.jl to point to system Conda
# This preemptively sets Conda.jl's metadata so it doesn't try to download its own
RUN mkdir -p $JULIA_DEPOT_PATH && \
    julia -e "using Conda; println(Conda.PYTHONDIR)" && \
    julia -e "ENV[\"CONDA_JL_CONDA_EXE\"]=\"/opt/conda/bin/conda\"; using Conda; println(Conda.PYTHONDIR)"

# 8. Install & Precompile Julia Packages
COPY Project.toml Manifest.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# 9. Clean up (but keep julia_depot/conda this time - it's harmless now)
RUN rm -rf /opt/julia_depot/registries \
    && rm -rf /opt/julia_depot/logs \
    && rm -rf /usr/local/julia/share/doc \
    && rm -rf /usr/local/julia/share/julia/test

# --- Stage 3: Final Image --- 
FROM continuumio/miniconda3:latest

WORKDIR /app

# 1. Copy patched Julia and depot
COPY --from=builder /usr/local/julia /usr/local/julia
COPY --from=builder /opt/julia_depot /opt/julia_depot

# 2. Symlink Julia
RUN ln -s /usr/local/julia/bin/julia /usr/local/bin/julia

# 3. Re-create the Conda environment
COPY environment.yml .
RUN conda env update -f environment.yml && \
    conda clean -afy

# 4. Runtime environment variables
ENV PYTHON="/opt/conda/envs/ap-env/bin/python"
ENV CONDA_JL_CONDA_EXE="/opt/conda/bin/conda"
ENV CONDA_JL_USE_MAMBA="no"
ENV JULIA_DEPOT_PATH="~/.julia:/opt/julia_depot"
ENV PATH="/opt/conda/envs/ap-env/bin:${PATH}"
ENV JULIA_PROJECT="/app"

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "ap-env"]
