# RunPod Llama.cpp Container - Status Report

## Contesto 🎯

**Obiettivo:** Creare un container minimale per RunPod con llama.cpp CUDA per eseguire modelli LLM su GPU NVIDIA A40/A100/H100.

**Ambiente di sviluppo locale:** Linux senza GPU NVIDIA - il container viene buildato e testato localmente solo per verificare la struttura, ma le funzionalità CUDA (llama-cli, llama-server) non possono essere testate completamente in locale.

**Ambiente di produzione:** RunPod con GPU NVIDIA e driver CUDA già installati - il container monta le librerie CUDA dall'host automaticamente.

---

## Cosa è stato fatto ✅

### 1. Dockerfile creato e configurato

- Base image: `nvidia/cuda:12.8.0-runtime-ubuntu22.04`
- llama.cpp precompilato (release b8575 da ai-dock) con CUDA 12.8
- Strumenti installati: wget, curl, git, vim-tiny, nano, htop, openssh-server, python3, pip, venv, libgomp1
- SSH server configurato (PermitRootLogin yes, PasswordAuthentication yes)
- Symlink per cache llama.cpp: `/root/.cache/llama.cpp` → `/workspace/models`

### 2. Immagine Docker pushata su GHCR

- Repository: `ghcr.io/hal9ooo/runpod-llama:latest`
- Digest ultimo push: `sha256:ae48987f9bc2eaa12b4935b94013e35be3f9c2e54c296456eb5fbea1be4ded1a`

### 3. File di progetto creati

- `Dockerfile` - Configurazione container
- `docker-compose.yml` - Testing locale
- `download_model.sh` - Script helper per download modelli
- `README.md` - Documentazione completa in inglese

### 4. Funzionalità testate con successo

- ✅ Container si avvia e rimane attivo
- ✅ SSH funziona (root login con password)
- ✅ llama-cli e llama-server sono disponibili in `/usr/local/bin`
- ✅ Librerie condivise CUDA installate e linkate correttamente
- ✅ Volume `/workspace` persistente configurato

**Nota:** I test locali verificano solo la struttura del container. Le funzionalità CUDA complete (esecuzione modelli su GPU) devono essere testate su RunPod dove le librerie `libcuda.so.1` sono fornite dall'host.

---

## Problemi aperti / Da testare ⚠️

### 1. ~~huggingface-cli PATH~~ ✅ RISOLTO

**Causa:** `huggingface_hub` 1.8.0 ha rinominato il CLI da `huggingface-cli` a **`hf`**.

- Il binario si trova in `/usr/local/bin/hf` (non `huggingface-cli`)
- `hf download`, `hf upload`, ecc. funzionano correttamente
- `ENV PATH="$PATH:/root/.local/bin"` nel Dockerfile è ridondante ma innocuo

**Comando corretto:**
```bash
hf download HauhauCS/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive \
    --include "*.gguf" \
    --local-dir /workspace/models
```

### 2. Symlink cache

**Problema:** I symlink `/root/.cache/models` e `/root/.cache/llama.cpp` puntano a `/workspace/models`, ma questo può creare conflitti con la cache di huggingface.

**Soluzione applicata:** Impostato `HF_HOME="/workspace/huggingface"` per separare le cache.

---

## Prossimi step per il nuovo agente 🔧

### ~~Priorità 1: Verificare huggingface-cli~~ ✅ RISOLTO

Il comando è `hf` (non `huggingface-cli`) dalla versione 1.8.0.

### Priorità 1: Testare download modello

```bash
# Scaricare un modello piccolo di test
docker run --rm -v ./workspace:/workspace ghcr.io/hal9ooo/runpod-llama:latest bash -c "
  hf download ggerganov/whisper.cpp models/ggml-base.en.bin --local-dir /workspace/test
  ls -la /workspace/test
"
```

### Priorità 3: Testare su RunPod

1. Creare nuovo pod con `ghcr.io/hal9ooo/runpod-llama:latest`
2. Montare volume persistente su `/workspace`
3. Testare download modello con huggingface-cli
4. Verificare che i file persistano dopo riavvio

---

## Comandi utili per debug

### Verificare immagine locale

```bash
docker inspect ghcr.io/hal9ooo/runpod-llama:latest | grep -i path
```

### Testare huggingface-cli

```bash
docker run --rm --entrypoint bash ghcr.io/hal9ooo/runpod-llama:latest -c "
  echo 'PATH:' \$PATH
  echo 'HF_HOME:' \$HF_HOME
  which huggingface-cli
  huggingface-cli --help
"
```

### Build e push manuale

```bash
cd /root/progetti/dev/runpod_llama
docker compose build --no-cache
docker tag runpod_llama-llama:latest ghcr.io/hal9ooo/runpod-llama:latest
docker push ghcr.io/hal9ooo/runpod-llama:latest
```

---

## Riferimenti

### Immagine Docker

- **Repository:** `ghcr.io/hal9ooo/runpod-llama`
- **Tag:** `latest`
- **Ultimo digest:** `sha256:ae48987f9bc2eaa12b4935b94013e35be3f9c2e54c296456eb5fbea1be4ded1a`

### File di configurazione

- [`Dockerfile`](Dockerfile)
- [`docker-compose.yml`](docker-compose.yml)
- [`README.md`](README.md)

### Comandi per scaricare modelli

```bash
# Con huggingface-cli (se funziona)
hf download HauhauCS/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive-IQ4_XS.gguf --local-dir /workspace/models
```
