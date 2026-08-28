#!/bin/bash
# Print the model file + extra llama flags that fit THIS host's RAM. Usage: eval "$(pick-model.sh)"
. "$(dirname "$0")/env.sh"
GB=$(( $(sysctl -n hw.memsize) / 1073741824 ))
if [ -n "${MOE_MODEL:-}" ]; then M="$MOE_MODEL"; X="${MOE_EXTRA:-}"
elif [ "$GB" -ge 32 ] && [ -f "$MODELS/qwen3.5-35b-a3b-q4km.gguf" ]; then M="$MODELS/qwen3.5-35b-a3b-q4km.gguf"; X="--moe-stream --moe-stream-cache 4 --moe-stream-io-threads $IO_THREADS"
elif [ "$GB" -ge 16 ] && [ -f "$MODELS/qwen3.5-35b-a3b-q4km.gguf" ]; then M="$MODELS/qwen3.5-35b-a3b-q4km.gguf"; X="--moe-stream --moe-stream-cache $CACHE_SLOTS --moe-stream-io-threads $IO_THREADS"
elif [ -f "$MODELS/Qwen3-4B-Instruct-2507-Q4_K_M.gguf" ]; then M="$MODELS/Qwen3-4B-Instruct-2507-Q4_K_M.gguf"; X=""
elif [ -f "$MODELS/qwen3-4b-thinking-q4.gguf" ]; then M="$MODELS/qwen3-4b-thinking-q4.gguf"; X=""   # thinking model: answers cost ~500 extra tokens
else M="$(ls "$MODELS"/*.gguf 2>/dev/null | head -1)"; X=""; fi
[ -n "$M" ] || { echo "echo 'no model in $MODELS' >&2; exit 1"; exit 1; }
echo "MODEL='$M'; EXTRA='$X'; HOST_GB=$GB"
