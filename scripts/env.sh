#!/bin/bash
# Shared config. Everything lives on the external drive ($WORK). Override via config.local.sh (gitignored).
WORK="${MOE_WORK:-/Volumes/x10/LLMs/moe-stream}"
LLAMA_DIR="$WORK/llama.cpp"
BIN="$LLAMA_DIR/build/bin"
MODELS="$WORK/models"            # symlinks/files: <name>.gguf
MEMORY="$WORK/memory"            # memory.db (SQLite FTS5) + kv/ (server slot saves)
LOGS="$WORK/logs"
PORT="${MOE_PORT:-8080}"
CTX="${MOE_CTX:-4096}"
IO_THREADS="${MOE_IO_THREADS:-4}"
CACHE_SLOTS="${MOE_CACHE_SLOTS:-24s}"   # --moe-stream-cache; 3*n_expert_used is the PR's floor
SWAP_DELTA_MB="${MOE_SWAP_DELTA_MB:-2500}" # guard: kill the runtime if swap grows this much
PR_FORK="https://github.com/freedomljc/llama.cpp.git"
PR_BRANCH="feat/moe-streaming-core"      # ggml-org/llama.cpp PR #25294
PR_COMMIT="1248fd8fa8cfebaece5ea992e4d951c1e18bb9d5"
HERE_ENV="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$HERE_ENV/../config.local.sh" ] && . "$HERE_ENV/../config.local.sh"
mkdir -p "$MODELS" "$MEMORY/kv" "$LOGS" 2>/dev/null || true
