# Use CUDA runtime base image matching the compilation toolkit
FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

# Install necessary packages for development and runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    vim-tiny \
    nano \
    htop \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale

# Download precompiled llama.cpp with CUDA support from ai-dock
# Using the latest release tag b8575
ENV LLAMA_CPP_CUDA_VERSION=b8575
RUN mkdir -p /opt/llama.cpp && \
    cd /opt/llama.cpp && \
    wget https://github.com/ai-dock/llama.cpp-cuda/releases/download/${LLAMA_CPP_CUDA_VERSION}/llama.cpp-${LLAMA_CPP_CUDA_VERSION}-cuda-12.8.tar.gz && \
    tar -xzf llama.cpp-${LLAMA_CPP_CUDA_VERSION}-cuda-12.8.tar.gz && \
    rm llama.cpp-${LLAMA_CPP_CUDA_VERSION}-cuda-12.8.tar.gz && \
    # Copy the essential binaries to /usr/local/bin (they are in the cuda-12.8 directory)
    cp cuda-12.8/llama-cli /usr/local/bin/ && \
    cp cuda-12.8/llama-server /usr/local/bin/ && \
    # Clean up the source directory to save space (optional)
    rm -rf /opt/llama.cpp/cuda-12.8

# Create workspace and cache symlink
RUN mkdir -p /workspace/models && ln -s /workspace/models /root/.cache

WORKDIR /workspace
CMD ["bash"]