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

### 3. Configure Networking

- **Expose TCP Ports:** `8080` — connessione diretta senza proxy Cloudflare (no timeout 524)
- **Expose HTTP Ports:** `8080` — accesso web UI tramite proxy (soggetto a timeout ~100s)

La porta TCP diretta e' consigliata per Harmony Writer: elimina i timeout del proxy Cloudflare sulle request lunghe. L'endpoint TCP sara' visibile nella dashboard sotto "Connect" -> "TCP Port Mappings" (es: `<pod-id>.runpod.io:12345`).

### 4. Start the Pod

- Select GPU (recommended: A40, A100, H100)
- Start container

## 📥 Quick Start: Download & Run

### One-Liner: IQ4_XS (48+ GB VRAM)

```bash
# 1. Download model
hf download HauhauCS/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive \
    Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    mmproj-Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-f16.gguf \
    --local-dir ~/.cache/llama.cpp && \
# 2. Start llama-server in background
nohup llama-server \
    -m ~/.cache/llama.cpp/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    -c 65536 -ngl 999 --host 0.0.0.0 --port 8080 \
    --flash-attn on --parallel 2 \
    --reasoning-budget 2048 \
    --temp 0.85 --top-p 0.95 --min-p 0.05 \
    --repeat-penalty 1.1 --repeat-last-n 256 \
    > ~/llama-server.log 2>&1 & \
# 3. View log
tail -f ~/llama-server.log
```

### One-Liner: Q4_K_P (40+ GB VRAM)

```bash
# 1. Download model
hf download HauhauCS/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive \
    Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf \
    --local-dir ~/.cache/llama.cpp && \
# 2. Start llama-server in background
nohup llama-server \
    -m ~/.cache/llama.cpp/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf \
    -c 65536 -ngl 999 --host 0.0.0.0 --port 8080 \
    --flash-attn on --parallel 2 \
    --reasoning-budget 2048 \
    --temp 0.85 --top-p 0.95 --min-p 0.05 \
    --repeat-penalty 1.1 --repeat-last-n 256 \
    > ~/llama-server.log 2>&1 & \Q
# 3. View log
tail -f ~/llama-server.log
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
    -m ~/.cache/llama.cpp/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    -c 65536 \
    -ngl 999 \
    --reasoning-budget 1024 \
    --temp 0.6 \
    --top-p 0.95 \
    -cnv
```

- `-c 65536` — 64k context window (sufficient for all pipeline phases)
- `-ngl 999` — offload all layers to GPU
- `--reasoning-budget 1024` — short reasoning (0 = disabled, -1 = unlimited)
- `-cnv` — interactive conversation mode

### Start llama-server (HTTP API)

```bash
llama-server \
    -m ~/.cache/llama.cpp/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    -c 65536 \
    -ngl 999 \
    --host 0.0.0.0 \
    --port 8080 \
    --flash-attn on \
    --parallel 2 \
    --reasoning-budget 2048 \
    --temp 0.85 \
    --top-p 0.95 \
    --min-p 0.05 \
    --repeat-penalty 1.1 \
    --repeat-last-n 256
```

- `--flash-attn` — riduce uso VRAM per il KV cache e velocizza
- `--parallel 2` — 2 slot concorrenti per generazione capitoli in parallelo
- `--reasoning-budget 2048` — **CRITICO**: limita il thinking mode a 2048 token per default.
  Il client Python sovrascrive per-request: `reasoning_budget=0` per capitoli (no thinking),
  `reasoning_budget=2048` per worldbuilding/synopsis/outline (thinking breve).
  Senza questo flag, il default è `-1` (illimitato) → causa loop di generazione nei capitoli.
- Thinking controllato per-request tramite `reasoning_budget` nell'extra_body della API call.

Then access `http://<pod-ip>:8080` for the web interface.

### Run in background (survives SSH disconnect)

Launch with `nohup` and redirect output to a log file:

```bash
nohup llama-server \
    -m ~/.cache/llama.cpp/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf \
    -c 65536 -ngl 999 --host 0.0.0.0 --port 8080 \
    --flash-attn on --parallel 2 \
    --reasoning-budget 2048 \
    --temp 0.85 --top-p 0.95 --min-p 0.05 \
    --repeat-penalty 1.1 --repeat-last-n 256 \
    > ~/llama-server.log 2>&1 &

echo "PID: $!"
```

**View the log** (from any session, even after reconnecting):

```bash
tail -f ~/llama-server.log
```

**Stop the server:**

```bash
# Find and kill by name
pkill -f llama-server

# Or by PID if you saved it
kill <PID>
```

## 🔌 SSH Access & Direct TCP

### SSH Connection (RunPod SSH Gateway)

```bash
ssh c63lzpqedqmzip-644110db@ssh.runpod.io -i ~/.ssh/id_ed25519
```

**Nota:** Usa l'autenticazione tramite chiave pubblica SSH. Assicurati che:
1. La tua chiave pubblica (`~/.ssh/id_ed25519.pub`) sia aggiunta al tuo account RunPod
2. I permessi della chiave privata siano corretti: `chmod 600 ~/.ssh/id_ed25519`

### Direct TCP Connection (consigliato)

RunPod espone le porte TCP direttamente. Nella dashboard "Connect" → "Direct TCP ports":

```
Llama tcp  69.30.85.16:22104:8080
```

Significa:
- IP pubblico: `69.30.85.16`
- Porta esterna: `22104`
- Porta interna container: `8080`

**Accedi direttamente via HTTP:**

```bash
curl http://69.30.85.16:22104/health
```

Oppure apri nel browser: `http://69.30.85.16:22104`

**Nota:** La connessione TCP diretta bypassa il proxy Cloudflare, eliminando i timeout sulle request lunghe (consigliato per Harmony Writer).

### SSH Tunnel (alternativa se TCP diretto non disponibile)

```bash
ssh c63lzpqedqmzip-644110db@ssh.runpod.io -i ~/.ssh/id_ed25519 -L 8080:localhost:8080
```

Poi accedi a `http://localhost:8080` nel browser.

**Nota:** Il tunnel SSH tramite gateway RunPod potrebbe avere limitazioni sul port forwarding.

## 📁 Directory Structure

```
~/
├── .cache/llama.cpp/  # Downloaded models (persistent)
└── llama-server.log   # Server log file
```

## 🔗 Cache Symlinks

The container includes automatic symlinks for cache:

- `~/.cache/llama.cpp` → default cache directory

Models downloaded with `hf download` go to `~/.cache/llama.cpp` by default.

## 🧰 Useful Commands

```bash
# List downloaded models
ls -lh ~/.cache/llama.cpp/

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
