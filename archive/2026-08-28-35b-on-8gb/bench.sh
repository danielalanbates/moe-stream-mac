#!/bin/bash
# One-shot generation with timing. Usage: bench.sh [n_tokens] [cache_gib]
set -euo pipefail
. "$(dirname "$0")/env.sh"
N="${1:-64}"; C="${2:-$CACHE_GIB}"
mkdir -p "$WORK/logs"; LOG="$WORK/logs/bench-$(date +%Y%m%d-%H%M%S)-c${C}.log"
"$LLAMA_DIR/build/bin/llama-cli" -m "$MODEL" \
  --moe-stream --moe-stream-cache "$C" --moe-stream-io-threads "$IO_THREADS" \
  --no-mmap --no-warmup -c 1024 -n "$N" -no-cnv \
  -p "Explain in two sentences why the sky is blue." 2>&1 | tee "$LOG" | grep -E "moe_stream|eval time|tokens per|zero-padding| E "
echo "log: $LOG"
