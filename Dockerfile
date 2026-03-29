# Use CUDA runtime base image matching the compilation toolkit
FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

# Install necessary packages for development and runtime
# Added: openssh-server, python3, pip, and other essentials for RunPod web terminal and SSH
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    vim-tiny \
    nano \
    htop \
    ca-certificates \
    openssh-server \
    python3 \
    python3-pip \
    python3-venv \
    libgomp1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale

# Install huggingface-cli for downloading models
RUN pip3 install --no-cache-dir huggingface_hub
ENV PATH="$PATH:/root/.local/bin"
ENV HF_HOME="/workspace/huggingface"

# Configure SSH server
RUN mkdir -p /run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config && \
    sed -i 's/session\s*required\s*pam_loginuid.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd

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
    # Copy shared libraries to /usr/local/lib
    cp cuda-12.8/*.so* /usr/local/lib/ && \
    # Create proper symlinks for the shared libraries
    cd /usr/local/lib && \
    ln -sf libggml.so.0 libggml.so && \
    ln -sf libggml-base.so.0 libggml-base.so && \
    ln -sf libggml-cpu.so.0 libggml-cpu.so && \
    ln -sf libggml-cuda.so.0 libggml-cuda.so && \
    ln -sf libllama.so.0 libllama.so && \
    ln -sf libmtmd.so.0 libmtmd.so && \
    # Clean up the source directory to save space (optional)
    rm -rf /opt/llama.cpp/cuda-12.8

# Update library cache and set LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
RUN ldconfig

# Create workspace and cache symlink
RUN mkdir -p /workspace/models && \
    mkdir -p /root/.cache && \
    ln -sfn /workspace/models /root/.cache/models && \
    ln -sfn /workspace/models /root/.cache/llama.cpp

# Set up entrypoint script to start SSH and keep container running
RUN printf '#!/bin/bash\nset -e\n\n# Start SSH daemon in background\n/usr/sbin/sshd\n\n# Keep container running with tail -f\nexec tail -f /dev/null\n' > /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]