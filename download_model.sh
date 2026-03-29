#!/bin/bash
# Script per scaricare il modello Qwen3.5-122B
# Usage: ./download_model.sh

MODEL_REPO="HauhauCS/Qwen3.5-122B-A10B-Uncensored-HauhauCS-Aggressive"
MODEL_DIR="/workspace/models"

echo "Downloading model from $MODEL_REPO to $MODEL_DIR..."
echo "This may take a while (model is ~62GB)..."

hf download "$MODEL_REPO" --include "*.gguf" --local-dir "$MODEL_DIR"

echo "Download complete!"
echo "Model location: $MODEL_DIR"
echo ""
echo "Usage example:"
echo "  llama-cli -m $MODEL_DIR/*.gguf -p 'Hello' -n 256"
