# RunPod Llama.cpp Template

Minimal Docker container for RunPod with **llama.cpp CUDA** and lightweight development tools.

## 🚀 Quick Start

### Docker Image

```
ghcr.io/hal9ooo/runpod-llama:latest
```

### Image Size

- **Compressed:** ~2.5 GB
- **Expanded:** ~5.5 GB

## ✨ Features

- 🎯 **llama.cpp** with CUDA 12.8 support (precompiled)
- 🔧 **Dev tools:** wget, curl, git, vim-tiny, nano, htop
- 🐍 **Python 3** with pip and venv
- 🔐 **SSH server** preconfigured (root login enabled)
- 📦 **hf CLI** for downloading models (huggingface_hub 1.8+)
- 💾 **Persistent volume** on `/workspace`

## 🛠️ Usage on RunPod

### 1. Create a new Pod

- Select **"Custom Template"**
- Enter image: `ghcr.io/hal9ooo/runpod-llama:latest`

### 2. Configure Volume

- Mount persistent volume on **`/workspace`**
- Recommended size: **64GB+** (models are large!)

### 3. Start the Pod

- Select GPU (recommended: A40, A100, H100)
- Start container

## 📥 Download a Model

Once the container is running, download your desired model:

```bash
# Download model weights + multimodal projector
hf download HauhauCS/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive \
    Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    mmproj-Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-f16.gguf \
    --local-dir /workspace/models
```

### Recommended Models (GGUF format)

| Model         | Size   | Quantization | VRAM Required |
| ------------- | ------ | ------------ | ------------- |
| Qwen3.5-122B  | ~62 GB | IQ4_XS       | 48+ GB        |
| Qwen3.5-122B  | ~45 GB | IQ3_M        | 40+ GB        |
| Llama-3.1-70B | ~35 GB | Q4_K_M       | 32+ GB        |
| Llama-3.1-8B  | ~5 GB  | Q8_0         | 8+ GB         |

## 🎮 Usage

### Inference with llama-cli

```bash
llama-cli \
    -m /workspace/models/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    -c 131072 \
    -ngl 999 \
    --reasoning-budget 1024 \
    --temp 0.6 \
    --top-p 0.95 \
    -cnv
```

- `-c 131072` — 128k context window
- `-ngl 999` — offload all layers to GPU
- `--reasoning-budget 1024` — short reasoning (0 = disabled, -1 = unlimited)
- `-cnv` — interactive conversation mode

### Start llama-server (HTTP API)

```bash
llama-server \
    -m /workspace/models/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    -c 131072 \
    -ngl 999 \
    --host 0.0.0.0 \
    --port 8080 \
    --temp 0.85 \
    --top-p 0.95 \
    --min-p 0.05 \
    --repeat-penalty 1.1 \
    --repeat-last-n 256
```

> **Think / No-think:** Use `/think` or `/nothink` at the start of your prompt to toggle reasoning mode on the fly — no server restart needed.

Then access `http://<pod-ip>:8080` for the web interface.

### Run in background (survives SSH disconnect)

Launch with `nohup` and redirect output to a log file on the persistent volume:

```bash
nohup llama-server \
    -m /workspace/models/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    -c 131072 -ngl 999 --host 0.0.0.0 --port 8080 \
    --temp 0.85 --top-p 0.95 --min-p 0.05 \
    --repeat-penalty 1.1 --repeat-last-n 256 \
    > /workspace/llama-server.log 2>&1 &

echo "PID: $!"
```

**View the log** (from any session, even after reconnecting):

```bash
tail -f /workspace/llama-server.log
```

**Stop the server:**

```bash
# Find and kill by name
pkill -f llama-server

# Or by PID if you saved it
kill <PID>
```

## 🔌 SSH Access

The container includes a preconfigured SSH server:

```bash
ssh root@<pod-ip>
```

Password is the one set in the RunPod panel.

## 📁 Directory Structure

```
/workspace/
├── models/          # Downloaded models (persistent)
└── ...              # Your other files
```

## 🔗 Cache Symlinks

The container includes automatic symlinks for cache:

- `/root/.cache/llama.cpp` → `/workspace/models`
- `/root/.cache/models` → `/workspace/models`

Models downloaded with `-hf` automatically go to the persistent volume.

## 🧰 Useful Commands

```bash
# List downloaded models
ls -lh /workspace/models/

# Disk space
df -h

# GPU usage
nvidia-smi
```

## 🏗️ Local Build (optional)

```bash
# Build image
docker compose build

# Local test
docker compose up -d

# Access container
docker exec -it runpod_llama-llama-1 bash
```

## 📋 Installed Packages

| Category   | Packages                            |
| ---------- | ----------------------------------- |
| **Base**   | wget, curl, git, ca-certificates    |
| **Editor** | vim-tiny, nano                      |
| **System** | htop, openssh-server                |
| **Python** | python3, python3-pip, python3-venv  |
| **LLM**    | llama-cli, llama-server (CUDA 12.8) |
| **HF**     | huggingface_hub                     |

## 🔧 Troubleshooting

### "libcuda.so.1 not found"

On RunPod, host CUDA libraries are mounted automatically. If you see this error locally, use `--gpus all` with Docker.

### Model too slow

- Use lower quantization (IQ2_XS, IQ3_M)
- Ensure model is loaded on GPU (`-ngl 999`)
- Check VRAM usage with `nvidia-smi`

### SSH not working

Verify port 22 is exposed in the RunPod template and use the correct password.

## 📄 License

This template is provided "as is" for personal and research use.

## 🙏 Credits

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - Inference engine
- [ai-dock](https://github.com/ai-dock/llama.cpp-cuda) - Precompiled CUDA builds
- [Hugging Face](https://huggingface.co/) - Model hub

---

**Happy inferencing! 🦙**
