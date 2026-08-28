#!/bin/bash
# Serve the model with experts streamed from the external drive. OpenAI-compatible on $PORT.
set -euo pipefail
. "$(dirname "$0")/env.sh"
if pgrep -f "llama-server.*moe-stream" >/dev/null; then echo "already running (one instance rule)"; exit 1; fi
exec "$LLAMA_DIR/build/bin/llama-server" -m "$MODEL" \
  --moe-stream --moe-stream-cache "$CACHE_GIB" --moe-stream-io-threads "$IO_THREADS" \
  --no-mmap --no-warmup -c "$CTX" --port "$PORT" "$@"
