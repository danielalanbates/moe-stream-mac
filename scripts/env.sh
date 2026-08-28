#!/bin/bash
# Shared config. Override any of these via config.local.sh (gitignored).
WORK="${MOE_WORK:-/Volumes/x10/LLMs/moe-stream}"          # on the external drive
LLAMA_DIR="$WORK/llama.cpp"
MODEL="${MOE_MODEL:-$WORK/Qwen3.5-35B-A3B-Q4_K_M.gguf}"
CACHE_GIB="${MOE_CACHE_GIB:-1}"      # expert cache budget (GiB). 8 GB Mac: 1–2
IO_THREADS="${MOE_IO_THREADS:-4}"
CTX="${MOE_CTX:-4096}"
PORT="${MOE_PORT:-8080}"
PR_FORK="https://github.com/freedomljc/llama.cpp.git"
PR_BRANCH="feat/moe-streaming-core"      # ggml-org/llama.cpp PR #25294
PR_COMMIT="1248fd8fa8cfebaece5ea992e4d951c1e18bb9d5"
[ -f "$(dirname "$0")/../config.local.sh" ] && . "$(dirname "$0")/../config.local.sh"
