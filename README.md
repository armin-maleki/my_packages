# Julia-Conda Hybrid Environment
This repository attempts to provide an efficient, multi-stage Docker environment for Julia 1.11.0 integrated with Miniconda3.


<p align="left">
  <img src="./assets/julia_logo.svg" alt="Julia Logo" height="100">
  &nbsp;&nbsp;
  <img src="./assets/conda_logo.svg" alt="Conda Logo" height="100">
</p>

## Build Architecture

The build process is divided into four stages to manage tools and dependencies while keeping the final image size manageable.

```mermaid
graph TD
    S0[<b>Stage 0: Tools</b><br/>Extracts patching tools]
    S1[<b>Stage 1: Julia</b><br/>Provides Julia binaries]
    S2[<b>Stage 2: Builder</b><br/>Patches Julia, creates Conda env,<br/>and precompiles packages]
    S3[<b>Stage 3: Runtime</b><br/>The final, lean image]

    S0 --> S2
    S1 --> S2
    S2 --> S3
```


