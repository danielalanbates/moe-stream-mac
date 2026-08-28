#!/bin/bash
# Fetch a llama.cpp-native GGUF (Ollama's GGUFs use different tensor names and will NOT load).
set -euo pipefail
. "$(dirname "$0")/env.sh"
URL="${1:-https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF/resolve/main/Qwen3.5-35B-A3B-Q4_K_M.gguf}"
mkdir -p "$WORK"
curl -L -C - --retry 20 --retry-delay 5 -o "$MODEL" "$URL"
