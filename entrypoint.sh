#!/bin/bash
set -e

# Start SSH daemon
/usr/sbin/sshd

# Create cache directory
mkdir -p ~/.cache/llama.cpp

# Download model
echo "Downloading model from ${MODEL_REPO}:${MODEL_FILE}..."
hf download "${MODEL_REPO}" "${MODEL_FILE}" --local-dir ~/.cache/llama.cpp

# Start llama-server in background
echo "Starting llama-server..."
nohup llama-server \
    -m ~/.cache/llama.cpp/${MODEL_FILE} \
    -c ${LLAMA_CONTEXT} -ngl 999 --host ${LLAMA_HOST} --port ${LLAMA_PORT} \
    --flash-attn on --parallel ${LLAMA_PARALLEL} \
    --reasoning-budget ${LLAMA_REASONING_BUDGET} \
    --temp ${LLAMA_TEMP} --top-p ${LLAMA_TOP_P} --min-p ${LLAMA_MIN_P} \
    --repeat-penalty ${LLAMA_REPEAT_PENALTY} --repeat-last-n ${LLAMA_REPEAT_LAST_N} \
    > ~/llama-server.log 2>&1 &

# Tail the log
echo "Tailing llama-server log..."
exec tail -f ~/llama-server.log
